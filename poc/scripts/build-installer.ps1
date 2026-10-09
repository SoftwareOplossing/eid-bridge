# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RuntimeDirectory,
    [Parameter(Mandatory)][string]$MiddlewareDll,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{64}$')][string]$MiddlewareSha256,
    [string]$MiddlewareProvenance = '',
    [string]$MiddlewareSourceArchive = '',
    [string]$ReleaseEvidence = '',
    [switch]$PublicRelease,
    [ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version = '1.1.0',
    [string]$Wix = 'wix',
    [string]$OutputDirectory = '',
    [string]$SignTool = '',
    [string]$SigningDlib = '',
    [string]$SigningMetadata = '',
    [string]$ExpectedPublisher = '',
    [switch]$Fixture
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$signingParameters = @($SignTool,$SigningDlib,$SigningMetadata,$ExpectedPublisher)
$signingCount = @($signingParameters | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
if ($signingCount -notin 0,4 -or ($Fixture -and $signingCount)) {
    throw 'Signing requires all four signing parameters and a real native build.'
}
$signing = $signingCount -eq 4
$runtime = (Resolve-Path -LiteralPath $RuntimeDirectory).Path
$middleware = (Resolve-Path -LiteralPath $MiddlewareDll).Path
$middlewareInfo = $null
$middlewareSource = $null
if ($MiddlewareProvenance) {
    $middlewareInfoPath = (Resolve-Path -LiteralPath $MiddlewareProvenance).Path
    $middlewareInfo = Get-Content -LiteralPath $middlewareInfoPath -Raw | ConvertFrom-Json
    if ($Fixture -or $middlewareInfo.origin -ne 'vendor_binary' -or
        $middlewareInfo.source_repository -ne 'https://github.com/Fedict/eid-mw' -or
        $middlewareInfo.source_mapping_classification -notin 'verified','strongly_supported_unverified','unresolved' -or
        $middlewareInfo.dll_sha256 -ne $MiddlewareSha256.ToLowerInvariant() -or
        $middlewareInfo.architecture -ne 'x64') {
        throw 'Invalid vendor middleware provenance record.'
    }
    $middlewareSource = (Resolve-Path -LiteralPath $MiddlewareSourceArchive).Path
    if ((Get-FileHash -LiteralPath $middlewareSource -Algorithm SHA256).Hash -ne $middlewareInfo.source_archive_sha256) {
        throw 'Middleware source archive does not match the provenance record.'
    }
}
if ($MiddlewareSourceArchive -and -not $middlewareInfo) { throw 'A source archive needs a matching provenance record.' }
if (-not $Fixture -and -not $middlewareInfo) { throw 'The selected vendor DLL requires its source/provenance record.' }
$middlewareSourceVerified = $middlewareInfo -and $middlewareInfo.source_mapping_classification -eq 'verified'
$nativeInfo = $null
if (-not $Fixture) {
    $nativeInfo = Get-Content -LiteralPath (Join-Path $runtime 'NATIVE-BUILD.json') -Raw | ConvertFrom-Json
    if ($nativeInfo.module_resolution -ne 'APP_DIRECTORY' -or
        (Get-FileHash -LiteralPath (Join-Path $runtime 'web-eid.exe') -Algorithm SHA256).Hash -ne $nativeInfo.app_sha256) {
        throw 'The installer needs the verified APP_DIRECTORY native build, not the portable PoC executable.'
    }
    $qtNotices = Join-Path $root 'third-party/qt/notices'
    $qtInventory = Get-Content -LiteralPath (Join-Path $qtNotices 'Qt-runtime-inventory.json') -Raw | ConvertFrom-Json
    if ($nativeInfo.qt_version -ne $qtInventory.qt_version) { throw 'Qt notices do not match the native build version.' }
    foreach ($entry in @($qtInventory.runtime_files) + @($qtInventory.mesa)) {
        if ((Get-FileHash -LiteralPath (Join-Path $runtime $entry.file) -Algorithm SHA256).Hash -ne $entry.sha256) {
            throw "Qt/Mesa notices do not match runtime file: $($entry.file)"
        }
    }
    $qtFiles = @(Get-ChildItem -LiteralPath $runtime -Recurse -File -Filter '*.dll' |
        Where-Object { $_.Name -like 'Qt6*' -or $_.DirectoryName -ne $runtime } |
        ForEach-Object { [IO.Path]::GetRelativePath($runtime,$_.FullName).Replace('\','/') })
    if (Compare-Object $qtFiles @($qtInventory.runtime_files.file)) {
        throw 'Qt runtime file inventory differs from its collected notices.'
    }
    foreach ($entry in @(
        @{name='Qt-THIRD-PARTY-NOTICES.txt';hash=$qtInventory.notice_sha256},
        @{name='Mesa-THIRD-PARTY-NOTICES.txt';hash=$qtInventory.mesa.notice_sha256}
    )) {
        if ((Get-FileHash -LiteralPath (Join-Path $qtNotices $entry.name) -Algorithm SHA256).Hash -ne $entry.hash) {
            throw "Qt/Mesa notice integrity check failed: $($entry.name)"
        }
    }
}
if ((Get-FileHash -LiteralPath $middleware -Algorithm SHA256).Hash -ne $MiddlewareSha256) {
    throw 'Middleware DLL does not match the recorded candidate.'
}
if (-not $Fixture) {
    $middlewareSignature = (Get-AuthenticodeSignature -LiteralPath $middleware).Status.ToString()
    if ($middlewareSignature -ne 'Valid') {
        throw 'Middleware requires its valid vendor signature.'
    }
    $middlewareBytes = [IO.File]::ReadAllBytes($middleware)
    $peOffset = [BitConverter]::ToInt32($middlewareBytes,0x3c)
    if ([BitConverter]::ToUInt16($middlewareBytes,$peOffset+4) -ne 0x8664) { throw 'Middleware DLL must be Windows x64.' }
    $middlewareVersion = (Get-Item -LiteralPath $middleware).VersionInfo
    if ($middlewareInfo -and ('{0}.{1}.{2}.{3}' -f $middlewareVersion.FileMajorPart,$middlewareVersion.FileMinorPart,
        $middlewareVersion.FileBuildPart,$middlewareVersion.FilePrivatePart) -ne $middlewareInfo.dll_version) {
        throw 'Middleware version differs from its vendor provenance record.'
    }
}
$releaseInfo = $null
if ($ReleaseEvidence) { $releaseInfo = Get-Content -LiteralPath $ReleaseEvidence -Raw | ConvertFrom-Json }
if ($PublicRelease -and ($Fixture -or -not $middlewareSourceVerified -or -not $releaseInfo -or
    $releaseInfo.middleware_sha256 -ne $MiddlewareSha256.ToLowerInvariant() -or
    $releaseInfo.app_sha256 -ne $nativeInfo.app_sha256 -or
    $releaseInfo.signature_verified -ne $true -or
    $releaseInfo.clean_windows_signing_verified -ne $true -or
    $releaseInfo.publisher_visual_studio_entitlement_confirmed -ne $true)) {
    throw 'Public packaging requires verified corresponding source, signing evidence for these binaries on clean Windows, and publisher Visual Studio entitlement.'
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
    # Windows 11 supplies the Direct3D compiler; Qt resolves it through
    # QSystemLibrary. Avoid redistributing the older Windows 8.1 SDK copy.
    if ($file.Name -eq 'd3dcompiler_47.dll') { continue }
    $relative = [IO.Path]::GetRelativePath($runtime, $file.FullName)
    $destination = Join-Path $payload $relative
    New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destination
}
Copy-Item -LiteralPath $middleware -Destination (Join-Path $payload 'beidpkcs11.dll') -Force
if ($signing) {
    & "$PSScriptRoot/sign-artifact.ps1" -File (Join-Path $payload 'web-eid.exe') `
        -SignTool $SignTool -SigningDlib $SigningDlib -SigningMetadata $SigningMetadata -ExpectedPublisher $ExpectedPublisher
}
$appHash = (Get-FileHash -LiteralPath (Join-Path $payload 'web-eid.exe') -Algorithm SHA256).Hash.ToLowerInvariant()
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
Copy-Item -LiteralPath (Join-Path $root 'third-party/belgian-eid/SOURCE.md') -Destination (Join-Path $licenses 'Belgian-eID-source.md')
Copy-Item -LiteralPath (Join-Path $root 'third-party/lets-peppol/LICENSE') -Destination (Join-Path $licenses 'LetsPeppol-MIT.txt')
Copy-Item -LiteralPath (Join-Path $root 'third-party/qt/LGPL-3.0-only.txt') -Destination (Join-Path $licenses 'LGPL-3.0.txt')
Copy-Item -LiteralPath (Join-Path $root 'third-party/qt/GPL-3.0-only.txt') -Destination (Join-Path $licenses 'GPL-3.0.txt')
Copy-Item -LiteralPath (Join-Path $root 'third-party/qt/README.md') -Destination (Join-Path $licenses 'Qt-source-and-notices.md')
Copy-Item -LiteralPath (Join-Path $root 'third-party/qt/notices') -Destination (Join-Path $licenses 'Qt') -Recurse
Copy-Item -LiteralPath (Join-Path $root 'third-party/microsoft') -Destination (Join-Path $licenses 'Microsoft') -Recurse
Copy-Item -LiteralPath (Join-Path $root 'third-party/openssl/README.md') -Destination (Join-Path $licenses 'OpenSSL-source-and-notices.md')
Get-ChildItem -LiteralPath (Join-Path $root 'third-party/belgian-eid') -Filter 'Toolkit-agreement-*.rtf' |
    Copy-Item -Destination $licenses
Copy-Item -LiteralPath (Join-Path $root 'third-party/belgian-eid/PKCS11-source-notices.txt') -Destination $licenses
if ($middlewareInfo) {
    Copy-Item -LiteralPath $middlewareInfoPath -Destination (Join-Path $payload 'MIDDLEWARE-PROVENANCE.json')
    Copy-Item -LiteralPath $middlewareSource -Destination (Join-Path $licenses 'Belgian-eID-source.zip')
    Copy-Item -LiteralPath (Join-Path $root 'third-party/belgian-eid/BUILD.md') -Destination (Join-Path $licenses 'Belgian-eID-build.md')
}
if (Test-Path -LiteralPath (Join-Path $runtime 'licenses')) {
    Copy-Item -LiteralPath (Join-Path $runtime 'licenses') -Destination $payload -Recurse -Force
}
if ($nativeInfo) { Copy-Item -LiteralPath (Join-Path $runtime 'NATIVE-BUILD.json') -Destination $payload }
WriteUtf8 (Join-Path $payload 'eu.webeid.json') ((Get-Content -LiteralPath (Join-Path $root 'install/eu.webeid.json.cmake') -Raw).Replace('@WEBEID_PATH@','web-eid.exe').Replace('Web-eid native application',"Let's Peppol eID Bridge"))
WriteUtf8 (Join-Path $payload 'eu.webeid.firefox.json') ((Get-Content -LiteralPath (Join-Path $root 'install/eu.webeid.firefox.json.cmake') -Raw).Replace('@WEBEID_PATH@','web-eid.exe').Replace('Web-eid native application',"Let's Peppol eID Bridge"))
WriteUtf8 (Join-Path $payload 'Onboarding.url') "[InternetShortcut]`r`nURL=https://be.letspeppol.org/onboarding`r`n"
Copy-Item -LiteralPath (Join-Path $root 'install/installer-readme.txt') -Destination (Join-Path $payload 'README.txt')
$metadata = [ordered]@{
    package_version = $Version; release_candidate = [bool](-not $PublicRelease); public_release = [bool]$PublicRelease; fixture = [bool]$Fixture
    application_signed = [bool]$signing
    publisher = $(if ($signing) { $ExpectedPublisher } else { $null })
    app_sha256 = $appHash
    app_unsigned_sha256 = $(if ($nativeInfo) { $nativeInfo.app_sha256 } else { $appHash })
    app_commit = $(if ($nativeInfo) { $nativeInfo.app_commit } else { 'fixture' })
    library_commit = $(if ($nativeInfo) { $nativeInfo.library_commit } else { 'fixture' })
    middleware_version = ('{0}.{1}.{2}.{3}' -f (Get-Item -LiteralPath $middleware).VersionInfo.FileMajorPart,
        (Get-Item -LiteralPath $middleware).VersionInfo.FileMinorPart,
        (Get-Item -LiteralPath $middleware).VersionInfo.FileBuildPart,
        (Get-Item -LiteralPath $middleware).VersionInfo.FilePrivatePart)
    middleware_sha256 = $MiddlewareSha256.ToLowerInvariant()
    corresponding_middleware_source_verified = [bool]$middlewareSourceVerified
    middleware_source_classification = $(if ($middlewareInfo) { $middlewareInfo.source_mapping_classification } else { 'unresolved' })
    middleware_origin = 'vendor-signed binary'
    middleware_source_commit = $(if ($middlewareInfo) { $middlewareInfo.source_commit } else { $null })
    publisher_visual_studio_entitlement_confirmed = [bool]($releaseInfo -and $releaseInfo.publisher_visual_studio_entitlement_confirmed -eq $true)
    qt_runtime_notices_verified = [bool](-not $Fixture)
    system_d3d_compiler = 'Windows 11 System32; SDK copy not bundled'
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
$message = Xml 'A different Web eID desktop application is registered. Uninstall it before installing this application. If you previously used the portable version, remove its registration using register-test-host.ps1 -Action Remove. Help: be.letspeppol.org/onboarding.'
WriteUtf8 (Join-Path $work 'hosts.wxs') ('<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"><Fragment>{0}<Launch Condition="{1}" Message="{2}" /><ComponentGroup Id="NativeHosts">{3}</ComponentGroup></Fragment></Wix>' -f ($searches -join "`n"),$condition,$message,($hosts -join "`n"))
$name = if ($Fixture) { 'FIXTURE-NOT-FOR-USE' } else { 'LetsPeppol-eID-Bridge' }
$kind = if ($signing) { 'signed-candidate' } else { 'unsigned-candidate' }
if ($PublicRelease) { $kind = if ($signing) { 'signed' } else { 'unsigned' } }
$msi = Join-Path $work "$name-$Version-windows-x64-$kind.msi"
& $Wix build -nologo -arch x64 -ext WixToolset.UI.wixext -ext WixToolset.Util.wixext `
    -d "RepoRoot=$root" -d "Version=$Version" `
    (Join-Path $root 'install/lets-peppol.wxs') (Join-Path $root 'install/browser-finish.wxs') `
    (Join-Path $work 'payload.wxs') (Join-Path $work 'hosts.wxs') -o $msi
if ($LASTEXITCODE -ne 0) { throw 'WiX MSI build or validation failed.' }
if ($signing) {
    & "$PSScriptRoot/sign-artifact.ps1" -File $msi -SignTool $SignTool `
        -SigningDlib $SigningDlib -SigningMetadata $SigningMetadata -ExpectedPublisher $ExpectedPublisher
}
# A failed build/signature check must not leave a new deliverable in the output folder.
$destinationMsi = Join-Path $OutputDirectory ([IO.Path]::GetFileName($msi))
Move-Item -LiteralPath $msi -Destination $destinationMsi -Force
$msi = $destinationMsi
$report = [ordered]@{
    msi = [IO.Path]::GetFileName($msi)
    msi_sha256 = (Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash.ToLowerInvariant()
    application = $metadata
    installer_signed = [bool]$signing
    public_release = [bool]$PublicRelease
    remaining_release_requirements = @()
}
if (-not $middlewareSourceVerified) { $report.remaining_release_requirements += 'Verify exact corresponding source for the selected vendor DLL' }
if (-not $releaseInfo -or $releaseInfo.clean_windows_signing_verified -ne $true -or
    $releaseInfo.middleware_sha256 -ne $MiddlewareSha256.ToLowerInvariant() -or
    $releaseInfo.app_sha256 -ne $nativeInfo.app_sha256) {
    $report.remaining_release_requirements += 'Clean Windows signing check for the selected new middleware'
}
if (-not $metadata.publisher_visual_studio_entitlement_confirmed) {
    $report.remaining_release_requirements += 'Publisher confirmation of Visual Studio runtime redistribution entitlement'
}
$report.signing_choice = $(if ($signing) { 'Publisher-signed' } else { 'Unsigned; Windows publisher/reputation warnings may apply' })
WriteUtf8 (Join-Path $OutputDirectory "BUILD-REPORT-$Version-$kind.json") ($report | ConvertTo-Json -Depth 5)
Write-Output "Built MSI: $msi"
Get-FileHash -LiteralPath $msi -Algorithm SHA256
