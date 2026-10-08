# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RuntimeDirectory,
    [Parameter(Mandatory)][string]$MiddlewareDll,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{64}$')][string]$MiddlewareSha256,
    [ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version = '0.1.3',
    [string]$Wix = 'wix',
    [string]$OutputDirectory = '',
    [switch]$Fixture
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$runtime = (Resolve-Path -LiteralPath $RuntimeDirectory).Path
$middleware = (Resolve-Path -LiteralPath $MiddlewareDll).Path
$nativeInfo = $null
if (-not $Fixture) {
    $nativeInfo = Get-Content -LiteralPath (Join-Path $runtime 'NATIVE-BUILD.json') -Raw | ConvertFrom-Json
    if ($nativeInfo.module_resolution -ne 'APP_DIRECTORY' -or
        (Get-FileHash -LiteralPath (Join-Path $runtime 'web-eid.exe') -Algorithm SHA256).Hash -ne $nativeInfo.app_sha256) {
        throw 'The installer needs the verified APP_DIRECTORY native build, not the portable PoC executable.'
    }
}
if ((Get-FileHash -LiteralPath $middleware -Algorithm SHA256).Hash -ne $MiddlewareSha256) {
    throw 'Middleware DLL does not match the recorded test candidate.'
}
if (-not $Fixture -and (Get-AuthenticodeSignature -LiteralPath $middleware).Status -ne 'Valid') {
    throw 'The test middleware candidate must have a valid Authenticode signature.'
}
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $root 'build/installer' }
$work = Join-Path $root ('build/installer-work-' + [guid]::NewGuid().ToString('N'))
$payload = Join-Path $work 'payload'
New-Item -ItemType Directory -Path $payload,$OutputDirectory -Force | Out-Null
function WriteUtf8([string]$path, [string]$content) {
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}
function Xml([string]$value) { [Security.SecurityElement]::Escape($value) }
function Id([string]$prefix, [string]$value) {
    $hash = [Security.Cryptography.SHA256]::Create()
    try { $bytes = $hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($value.ToLowerInvariant())) }
    finally { $hash.Dispose() }
    $prefix + ([BitConverter]::ToString($bytes).Replace('-', '').Substring(0,24))
}
foreach ($file in Get-ChildItem -LiteralPath $runtime -Recurse -File) {
    if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Runtime payload contains a reparse point.' }
    if ($file.Extension -notin '.dll','.qm' -and $file.Name -notin 'web-eid.exe','qt.conf') { continue }
    $relative = [IO.Path]::GetRelativePath($runtime, $file.FullName)
    $destination = Join-Path $payload $relative
    New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destination
}
Copy-Item -LiteralPath $middleware -Destination (Join-Path $payload 'beidpkcs11.dll') -Force
foreach ($required in 'web-eid.exe','Qt6Core.dll','Qt6Gui.dll','Qt6Widgets.dll',
    'platforms/qwindows.dll','libcrypto-3-x64.dll','libssl-3-x64.dll',
    'msvcp140.dll','vcruntime140.dll','vcruntime140_1.dll','beidpkcs11.dll') {
    if (-not (Test-Path -LiteralPath (Join-Path $payload $required))) { throw "Missing runtime file: $required" }
}
$licenses = Join-Path $payload 'licenses'
New-Item -ItemType Directory -Path $licenses -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $licenses 'Web-eID-MIT.txt')
Copy-Item -LiteralPath (Join-Path $root 'lib/libelectronic-id/LICENSE') -Destination (Join-Path $licenses 'libelectronic-id-MIT.txt')
Copy-Item -LiteralPath (Join-Path $root 'third-party/belgian-eid/LICENSE') -Destination (Join-Path $licenses 'Belgian-eID-LGPL.txt')
Copy-Item -LiteralPath (Join-Path $root 'third-party/lets-peppol/LICENSE') -Destination (Join-Path $licenses 'LetsPeppol-MIT.txt')
Copy-Item -LiteralPath (Join-Path $root 'third-party/qt/LGPL-3.0-only.txt') -Destination (Join-Path $licenses 'LGPL-3.0.txt')
Copy-Item -LiteralPath (Join-Path $root 'third-party/qt/GPL-3.0-only.txt') -Destination (Join-Path $licenses 'GPL-3.0.txt')
Copy-Item -LiteralPath (Join-Path $root 'third-party/qt/README.md') -Destination (Join-Path $licenses 'Qt-source-and-notices.md')
if (Test-Path -LiteralPath (Join-Path $runtime 'licenses')) {
    Copy-Item -LiteralPath (Join-Path $runtime 'licenses') -Destination $payload -Recurse -Force
}
if ($nativeInfo) { Copy-Item -LiteralPath (Join-Path $runtime 'NATIVE-BUILD.json') -Destination $payload }
WriteUtf8 (Join-Path $payload 'eu.webeid.json') ((Get-Content -LiteralPath (Join-Path $root 'install/eu.webeid.json.cmake') -Raw).Replace('@WEBEID_PATH@','web-eid.exe').Replace('Web-eid native application',"Let's Peppol eID Bridge"))
WriteUtf8 (Join-Path $payload 'eu.webeid.firefox.json') ((Get-Content -LiteralPath (Join-Path $root 'install/eu.webeid.firefox.json.cmake') -Raw).Replace('@WEBEID_PATH@','web-eid.exe').Replace('Web-eid native application',"Let's Peppol eID Bridge"))
WriteUtf8 (Join-Path $payload 'Onboarding.url') "[InternetShortcut]`r`nURL=https://be.letspeppol.org/onboarding`r`n"
Copy-Item -LiteralPath (Join-Path $root 'install/installer-readme.txt') -Destination (Join-Path $payload 'README.txt')
$metadata = [ordered]@{
    package_version = $Version; test_build = $true; fixture = [bool]$Fixture
    app_commit = $(if ($nativeInfo) { $nativeInfo.app_commit } else { 'fixture' })
    library_commit = $(if ($nativeInfo) { $nativeInfo.library_commit } else { 'fixture' })
    middleware_version = (Get-Item -LiteralPath $middleware).VersionInfo.FileVersion
    middleware_sha256 = $MiddlewareSha256.ToLowerInvariant()
    corresponding_middleware_source_verified = $false
    module_resolution = $(if ($Fixture) { 'fixture-not-for-use' } else { 'APP_DIRECTORY' })
    compiler = 'WiX 4.0.6'
}
WriteUtf8 (Join-Path $payload 'BUILD-INFO.json') ($metadata | ConvertTo-Json)
$hashes = Get-ChildItem -LiteralPath $payload -Recurse -File | Sort-Object FullName | ForEach-Object {
    '{0} *{1}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), [IO.Path]::GetRelativePath($payload, $_.FullName)
}
WriteUtf8 (Join-Path $payload 'SHA256SUMS.txt') ($hashes -join "`n")

# Generate one deterministic component per file, keeping the upstream MSI source untouched.
$components = [Collections.Generic.List[string]]::new()
$directories = [Collections.Generic.List[string]]::new()
$directoryIds = @{ '.' = 'INSTALLFOLDER' }
foreach ($directory in Get-ChildItem -LiteralPath $payload -Recurse -Directory | Sort-Object FullName) {
    $relative = [IO.Path]::GetRelativePath($payload, $directory.FullName)
    $parent = [IO.Path]::GetRelativePath($payload, $directory.Parent.FullName)
    $directoryId = Id 'D_' $relative
    $directoryIds[$relative] = $directoryId
    $directories.Add(('<DirectoryRef Id="{0}"><Directory Id="{1}" Name="{2}" /></DirectoryRef>' -f $directoryIds[$parent],$directoryId,(Xml $directory.Name)))
}
foreach ($file in Get-ChildItem -LiteralPath $payload -Recurse -File | Sort-Object FullName) {
    $relative = [IO.Path]::GetRelativePath($payload, $file.FullName)
    $parent = [IO.Path]::GetRelativePath($payload, $file.DirectoryName)
    $fileId = Id 'F_' $relative
    $components.Add(('<Component Id="C_{0}" Directory="{1}" Guid="*" Bitness="always64"><File Id="{0}" Source="{2}" KeyPath="yes" /></Component>' -f $fileId,$directoryIds[$parent],(Xml $file.FullName)))
}
WriteUtf8 (Join-Path $work 'payload.wxs') ('<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"><Fragment>{0}<ComponentGroup Id="PayloadFiles">{1}</ComponentGroup></Fragment></Wix>' -f ($directories -join "`n"),($components -join "`n"))

# Refuse conflicts in every registry view browsers can consult, including the old HKCU PoC.
$searches = [Collections.Generic.List[string]]::new()
$hosts = [Collections.Generic.List[string]]::new()
$conditions = [Collections.Generic.List[string]]::new()
foreach ($browser in 'Edge','Chrome','Firefox') {
    $registry = switch ($browser) { Edge {'Microsoft\Edge'} Chrome {'Google\Chrome'} Firefox {'Mozilla'} }
    $manifest = if ($browser -eq 'Firefox') { 'eu.webeid.firefox.json' } else { 'eu.webeid.json' }
    $expected = if ($browser -eq 'Firefox') { 'EXPECTEDFIREFOXHOST' } else { 'EXPECTEDHOST' }
    foreach ($view in '32','64') {
        foreach ($hive in 'HKCU','HKLM') {
            $property = "HOST_${browser}_${view}_${hive}".ToUpperInvariant()
            $key = "SOFTWARE\$registry\NativeMessagingHosts\eu.webeid"
            $searches.Add(('<Property Id="{0}" Secure="yes"><RegistrySearch Id="Search_{0}" Root="{1}" Key="{2}" Type="raw" Bitness="always{3}" /></Property>' -f $property,$hive,$key,$view))
            $conditions.Add("(NOT $property OR (OWNINSTALLDIR AND $property = $expected))")
            if ($hive -eq 'HKLM') {
                $hosts.Add(('<Component Id="NativeHost_{0}_{1}" Directory="INSTALLFOLDER" Guid="*" Bitness="always{1}"><RegistryValue Root="HKLM" Key="{2}" Type="string" Value="[INSTALLFOLDER]{3}" KeyPath="yes" /></Component>' -f $browser,$view,$key,$manifest))
            }
        }
    }
}
$condition = Xml ($conditions -join ' AND ')
$message = Xml 'A different Web eID native host is registered. Remove the earlier PoC registration with register-test-host.ps1 -Action Remove, or uninstall the conflicting native app, then retry. No existing host was replaced.'
WriteUtf8 (Join-Path $work 'hosts.wxs') ('<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"><Fragment>{0}<Launch Condition="{1}" Message="{2}" /><ComponentGroup Id="NativeHosts">{3}</ComponentGroup></Fragment></Wix>' -f ($searches -join "`n"),$condition,$message,($hosts -join "`n"))
$name = if ($Fixture) { 'FIXTURE-NOT-FOR-USE' } else { 'LetsPeppol-eID-Bridge' }
$msi = Join-Path $OutputDirectory "$name-$Version-windows-x64-test.msi"
& $Wix build -nologo -arch x64 -ext WixToolset.UI.wixext -ext WixToolset.Util.wixext `
    -d "RepoRoot=$root" -d "Version=$Version" `
    (Join-Path $root 'install/lets-peppol.wxs') (Join-Path $root 'install/browser-finish.wxs') `
    (Join-Path $work 'payload.wxs') (Join-Path $work 'hosts.wxs') -o $msi
if ($LASTEXITCODE -ne 0) { throw 'WiX MSI build or validation failed.' }
Write-Output "Built MSI: $msi"
Get-FileHash -LiteralPath $msi -Algorithm SHA256
