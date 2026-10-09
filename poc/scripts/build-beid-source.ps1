# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SourceDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [string]$SourceCommit = '5b2d101d09fcdb550098de1196cd64f82b431744'
)
$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $SourceDirectory).Path
if ((& git -C $source rev-parse HEAD) -ne $SourceCommit -or $LASTEXITCODE) { throw 'Unexpected middleware source commit.' }
if (& git -C $source status --porcelain) { throw 'Build from a clean upstream checkout.' }
$revision = [int](& git -C $source rev-list --count HEAD)
$versionScript = Get-Content -LiteralPath (Join-Path $source 'scripts/windows/set_eidmw_version.cmd') -Raw
$parts = @(1..3 | ForEach-Object {
    if ($versionScript -notmatch "(?m)^@SET BASE_VERSION$_=(\d+)") { throw 'Cannot determine upstream base version.' }
    $Matches[1]
})
$version = ($parts + @($revision)) -join '.'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$vsRoot = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsRoot) { throw 'A licensed Visual Studio installation with the C++ workload is required.' }
$msbuild = Join-Path $vsRoot 'MSBuild/Current/Bin/MSBuild.exe'
$output = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $output -Force | Out-Null
Push-Location $source
try {
    # Invoke only upstream's version generator and the DLL project. Do not run
    # its installer/signing scripts, import certificates or install middleware.
    & $env:ComSpec /d /c scripts\windows\create_eidmw_version_files.cmd
    if ($LASTEXITCODE) { throw 'Upstream version generation failed.' }
    & $msbuild cardcomm/pkcs11/VS_2022/beidpkcs11.vcxproj /m /nologo /v:minimal /p:Configuration=Release /p:Platform=x64
    if ($LASTEXITCODE) { throw 'Upstream PKCS#11 source build failed.' }
    & git diff --exit-code -- cardcomm/pkcs11 doc/sdk/include
    if ($LASTEXITCODE) { throw 'The build changed upstream middleware code.' }
} finally { Pop-Location }
$dll = Join-Path $source 'cardcomm/pkcs11/VS_2022/Binaries/x64_Release/beidpkcs11.dll'
$info = (Get-Item -LiteralPath $dll).VersionInfo
$actualVersion = '{0}.{1}.{2}.{3}' -f $info.FileMajorPart,$info.FileMinorPart,$info.FileBuildPart,$info.FilePrivatePart
if ($actualVersion -ne $version) { throw "Unexpected DLL version: $actualVersion; expected $version" }
$bytes = [IO.File]::ReadAllBytes($dll)
$peOffset = [BitConverter]::ToInt32($bytes,0x3c)
if ([BitConverter]::ToUInt16($bytes,$peOffset+4) -ne 0x8664) { throw 'The DLL is not Windows x64.' }
Copy-Item -LiteralPath $dll -Destination (Join-Path $output 'beidpkcs11.dll')
$archive = Join-Path $output "eid-mw-$SourceCommit-source.zip"
& git -C $source archive --format=zip --prefix=eid-mw/ -o $archive $SourceCommit
if ($LASTEXITCODE) { throw 'Source archive generation failed.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($archive,[IO.Compression.ZipArchiveMode]::Update)
try {
    $header = Join-Path $source 'scripts/windows/beidversions.h'
    $null = [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$header,'eid-mw/scripts/windows/beidversions.h')
} finally { $zip.Dispose() }
$record = [ordered]@{
    origin = 'source_build'; source_repository = 'https://github.com/Fedict/eid-mw'
    source_commit = $SourceCommit; git_revision_count = $revision
    source_mapping_classification = 'verified'; modifications = 'None; upstream-generated version header included'
    dll_version = $actualVersion; architecture = 'x64'
    dll_sha256 = (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash.ToLowerInvariant()
    dll_signature_status = (Get-AuthenticodeSignature -LiteralPath $dll).Status.ToString()
    source_archive = [IO.Path]::GetFileName($archive)
    source_archive_sha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    build_project = 'cardcomm/pkcs11/VS_2022/beidpkcs11.vcxproj'
    build_configuration = 'Release|x64'; build_tool = (& $msbuild -version -nologo | Select-Object -Last 1)
    workflow_run = $env:GITHUB_RUN_ID; workflow_commit = $env:GITHUB_SHA
}
[IO.File]::WriteAllText((Join-Path $output 'MIDDLEWARE-BUILD.json'),($record | ConvertTo-Json),[Text.UTF8Encoding]::new($false))
Write-Output "Built unmodified upstream PKCS#11 $actualVersion and its complete source snapshot."
