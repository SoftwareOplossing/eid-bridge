# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Msi,
    [Parameter(Mandatory)][string]$ExtractedFiles,
    [Parameter(Mandatory)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$installer = New-Object -ComObject WindowsInstaller.Installer
$database = $installer.OpenDatabase((Resolve-Path -LiteralPath $Msi).Path, 0)
function Rows([string]$sql, [int]$columns) {
    $view = $database.OpenView($sql)
    try {
        $null = $view.Execute()
        while ($record = $view.Fetch()) {
            $row = @(for ($index = 1; $index -le $columns; $index++) { $record.StringData($index) })
            ,$row
        }
    } finally { $null = $view.Close() }
}
function LongName([string]$name) {
    $name = ($name -split ':', 2)[0]
    $name = ($name -split '\|')[-1]
    if ($name -eq '.' -or $name -eq '..' -or $name.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        throw 'Invalid MSI file/directory name.'
    }
    $name
}
$directories = @{}
foreach ($row in Rows 'SELECT `Directory`, `Directory_Parent`, `DefaultDir` FROM `Directory`' 3) {
    $directories[$row[0]] = @{ parent = $row[1]; name = $row[2] }
}
$components = @{}
foreach ($row in Rows 'SELECT `Component`, `Directory_` FROM `Component`' 2) { $components[$row[0]] = $row[1] }
if (Test-Path -LiteralPath $OutputDirectory) { throw 'Use a new output directory for extracted payload verification.' }
$output = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $output | Out-Null
$files = @{}
# Resolve paths independently from the MSI Directory/Component/File tables.
foreach ($row in Rows 'SELECT `File`, `Component_`, `FileName` FROM `File`' 3) {
    $relative = LongName $row[2]
    $directory = $components[$row[1]]
    $visited = @{}
    while ($directory -ne 'INSTALLFOLDER') {
        if (-not $directories.ContainsKey($directory) -or $visited.ContainsKey($directory)) { throw 'Invalid directory graph.' }
        $visited[$directory] = $true
        $relative = Join-Path (LongName $directories[$directory].name) $relative
        $directory = $directories[$directory].parent
    }
    $destination = [IO.Path]::GetFullPath((Join-Path $output $relative))
    if (-not $destination.StartsWith($output + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'MSI path escapes the reconstructed payload.'
    }
    if ($files.ContainsKey($relative)) { throw 'Duplicate payload file.' }
    $files[$relative] = $destination
    New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $ExtractedFiles $row[0]) -Destination $destination
}
$checked = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $output 'SHA256SUMS.txt')) {
    if ($line -notmatch '^([0-9a-f]{64}) \*(.+)$') { throw 'Malformed payload hash manifest.' }
    $digest = $Matches[1]
    $relative = $Matches[2]
    if (-not $files.ContainsKey($relative) -or $checked.ContainsKey($relative)) { throw 'Unknown or duplicate manifest file.' }
    if ((Get-FileHash -LiteralPath $files[$relative] -Algorithm SHA256).Hash -ne $digest) { throw "Extracted payload hash mismatch: $relative" }
    $checked[$relative] = $true
}
if ($checked.Count -ne $files.Count - 1) { throw 'A payload file was omitted from the hash manifest.' }
$build = Get-Content -LiteralPath (Join-Path $output 'NATIVE-BUILD.json') -Raw | ConvertFrom-Json
$package = Get-Content -LiteralPath (Join-Path $output 'BUILD-INFO.json') -Raw | ConvertFrom-Json
if ($build.module_resolution -ne 'APP_DIRECTORY' -or
    $package.app_unsigned_sha256 -ne $build.app_sha256 -or
    (Get-FileHash -LiteralPath (Join-Path $output 'web-eid.exe') -Algorithm SHA256).Hash -ne $package.app_sha256) {
    throw 'Extracted application differs from verified installer build.'
}
if ($package.application_signed) {
    $signature = Get-AuthenticodeSignature -LiteralPath (Join-Path $output 'web-eid.exe')
    if ($signature.Status -ne 'Valid' -or -not $signature.TimeStamperCertificate -or
        $signature.SignerCertificate.GetNameInfo([Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $false) -cne $package.publisher) {
        throw 'Packaged application lacks the expected timestamped publisher signature.'
    }
} elseif ($package.app_sha256 -ne $build.app_sha256) {
    throw 'Unsigned package changed the original native application.'
}
$middlewarePath = Join-Path $output 'beidpkcs11.dll'
if ((Get-FileHash -LiteralPath $middlewarePath -Algorithm SHA256).Hash -ne $package.middleware_sha256) {
    throw 'Selected middleware differs from the package record.'
}
if (Test-Path -LiteralPath (Join-Path $output 'MIDDLEWARE-PROVENANCE.json')) {
    $provenance = Get-Content -LiteralPath (Join-Path $output 'MIDDLEWARE-PROVENANCE.json') -Raw | ConvertFrom-Json
    $middlewareVersion = (Get-Item -LiteralPath $middlewarePath).VersionInfo
    $numericVersion = '{0}.{1}.{2}.{3}' -f $middlewareVersion.FileMajorPart,$middlewareVersion.FileMinorPart,
        $middlewareVersion.FileBuildPart,$middlewareVersion.FilePrivatePart
    if ($provenance.dll_sha256 -ne $package.middleware_sha256 -or
        $provenance.dll_version -ne $numericVersion -or
        $provenance.source_mapping_classification -ne $package.middleware_source_classification -or
        (Get-FileHash -LiteralPath (Join-Path $output 'licenses/Belgian-eID-source.zip') -Algorithm SHA256).Hash -ne $provenance.source_archive_sha256 -or
        (Get-AuthenticodeSignature -LiteralPath $middlewarePath).Status -ne 'Valid') {
        throw 'Vendor middleware, source archive or provenance record does not match.'
    }
    if ($package.corresponding_middleware_source_verified -ne ($provenance.source_mapping_classification -eq 'verified') -or
        ($package.public_release -and -not $package.corresponding_middleware_source_verified)) {
        throw 'Public/source verification flags overstate the recorded evidence.'
    }
    foreach ($required in 'licenses/Belgian-eID-build.md','licenses/PKCS11-source-notices.txt') {
        if (-not (Test-Path -LiteralPath (Join-Path $output $required))) { throw "Missing middleware build/notice file: $required" }
    }
}
if ($package.qt_runtime_notices_verified) {
    $qt = Get-Content -LiteralPath (Join-Path $output 'licenses/Qt/Qt-runtime-inventory.json') -Raw | ConvertFrom-Json
    foreach ($entry in @($qt.runtime_files) + @($qt.mesa)) {
        if ((Get-FileHash -LiteralPath (Join-Path $output $entry.file) -Algorithm SHA256).Hash -ne $entry.sha256) {
            throw "Packaged Qt/Mesa file differs from its official SDK inventory: $($entry.file)"
        }
    }
    if ((Get-FileHash -LiteralPath (Join-Path $output 'licenses/Qt/Qt-THIRD-PARTY-NOTICES.txt') -Algorithm SHA256).Hash -ne $qt.notice_sha256 -or
        (Get-FileHash -LiteralPath (Join-Path $output 'licenses/Qt/Mesa-THIRD-PARTY-NOTICES.txt') -Algorithm SHA256).Hash -ne $qt.mesa.notice_sha256) {
        throw 'Extracted Qt/Mesa notices differ from the audited inventory.'
    }
    foreach ($required in 'licenses/Toolkit-agreement-en.rtf','licenses/Toolkit-agreement-nl.rtf',
        'licenses/Toolkit-agreement-fr.rtf','licenses/Toolkit-agreement-de.rtf',
        'licenses/Microsoft/vc-runtime-2015-2022-terms.txt','licenses/Microsoft/vs-community-2022-terms.txt',
        'licenses/OpenSSL-source-and-notices.md','licenses/Qt/build-records/config_qtbase.summary',
        'licenses/Qt/build-records/config_qtsvg.summary') {
        if (-not (Test-Path -LiteralPath (Join-Path $output $required))) { throw "Missing packaged notice/build record: $required" }
    }
    if (Test-Path -LiteralPath (Join-Path $output 'd3dcompiler_47.dll')) {
        throw 'Windows 11 installer unnecessarily bundles the legacy SDK Direct3D compiler.'
    }
}
$hostManifest = Get-Content -LiteralPath (Join-Path $output 'eu.webeid.json') -Raw | ConvertFrom-Json
if ($hostManifest.name -ne 'eu.webeid' -or $hostManifest.path -ne 'web-eid.exe' -or $hostManifest.type -ne 'stdio' -or
    $hostManifest.allowed_origins.Count -ne 2 -or
    'chrome-extension://gnmckgbandlkacikdndelhfghdejfido/' -notin $hostManifest.allowed_origins -or
    'chrome-extension://ncibgoaomkmdpilpocfeponihegamlic/' -notin $hostManifest.allowed_origins) { throw 'Wrong browser manifest.' }
$firefox = Get-Content -LiteralPath (Join-Path $output 'eu.webeid.firefox.json') -Raw | ConvertFrom-Json
if ($firefox.name -ne 'eu.webeid' -or $firefox.path -ne 'web-eid.exe' -or $firefox.type -ne 'stdio' -or
    $firefox.allowed_extensions.Count -ne 1 -or $firefox.allowed_extensions[0] -ne '{e68418bc-f2b0-4459-a9ea-3e72b6751b07}') {
    throw 'Wrong Firefox manifest.'
}
Write-Output "Verified $($checked.Count) actual CAB payload files and native manifests. No installation was performed."
