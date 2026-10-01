# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{64}$')][string]$ExpectedSha256,
    [string]$SourceDll = "$env:WINDIR\System32\beidpkcs11.dll"
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$source = (Resolve-Path -LiteralPath $SourceDll).Path
if ((Get-Item -LiteralPath $source).Length -eq 0) { throw 'Source DLL is empty.' }
$actual = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if ($actual -ne $ExpectedSha256) { throw 'Source DLL hash differs from the approved test candidate.' }
$signature = Get-AuthenticodeSignature -LiteralPath $source
if ($signature.Status -ne 'Valid') { throw 'Source DLL does not have a valid Authenticode signature.' }
$probe = Join-Path $root 'build/poc-native/beid-probe.exe'
if (-not (Test-Path $probe)) { throw 'Build the native probe first (see poc/README.md).' }

$target = Join-Path $root 'build/clean-pc-test-kit'
New-Item -ItemType Directory -Path $target -Force | Out-Null
$files = @(
    @{ source = $source; name = 'beidpkcs11.dll' },
    @{ source = $probe; name = 'beid-probe.exe' },
    @{ source = (Join-Path $root 'third-party/belgian-eid/LICENSE'); name = 'Belgian-eID-LGPL.txt' },
    @{ source = (Join-Path $root 'poc/scripts/clean-pc-preflight.ps1'); name = 'clean-pc-preflight.ps1' }
)
foreach ($file in $files) { Copy-Item -LiteralPath $file.source -Destination (Join-Path $target $file.name) -Force }
$version = (Get-Item -LiteralPath $source).VersionInfo.FileVersion
@"
Experimental private-DLL test kit; NOT an installer or release package.
Source: locally installed Belgian eID middleware DLL, version $version
SHA-256: $($actual.ToLowerInvariant())
Authenticode: valid at staging time
Matching corresponding source for this installed binary has not been established.
Use only on a controlled clean test PC. Keep normal Belgian middleware uninstalled.
Combine with the portable Windows app artifact in C:\LetsPeppolPoC after its CI build passes.
Run clean-pc-preflight.ps1 before testing and save its result privately.
Run beid-probe.exe C:\LetsPeppolPoC\beidpkcs11.dll --require-token.
Never send or record a card PIN.
"@ | Set-Content -LiteralPath (Join-Path $target 'TEST-KIT.txt') -Encoding utf8
$archive = Join-Path $root 'build/clean-pc-test-kit.zip'
Compress-Archive -LiteralPath @(
    ($files | ForEach-Object { Join-Path $target $_.name })
    (Join-Path $target 'TEST-KIT.txt')
) `
    -DestinationPath $archive -Force
Write-Output "Staged test kit: $archive"
