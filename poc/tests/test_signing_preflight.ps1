# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RuntimeDirectory, [Parameter(Mandatory)][string]$MiddlewareDll)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$work = Join-Path $root ('build/signing-preflight-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
function Reject([scriptblock]$operation, [string]$message) {
    try { & $operation } catch {
        if ($_.Exception.Message -notlike "*$message*") { throw }
        return
    }
    throw 'Signing preflight unexpectedly accepted an unsafe input.'
}
$builder = Join-Path $root 'poc/scripts/build-installer.ps1'
Reject { & $builder -RuntimeDirectory $RuntimeDirectory -MiddlewareDll $MiddlewareDll `
    -MiddlewareSha256 ('0' * 64) -SigningMetadata 'partial-config.json' } 'all four signing parameters'
Reject { & $builder -RuntimeDirectory $RuntimeDirectory -MiddlewareDll $MiddlewareDll `
    -MiddlewareSha256 ('0' * 64) -Fixture -SignTool 'tool' -SigningDlib 'dlib' `
    -SigningMetadata 'metadata' -ExpectedPublisher 'publisher' } 'real native build'
$signer = Join-Path $root 'poc/scripts/sign-artifact.ps1'
$arguments = @{
    SignTool = Join-Path $work 'must-not-run.ps1'
    SigningDlib = (Resolve-Path -LiteralPath $MiddlewareDll).Path
    SigningMetadata = Join-Path $root 'install/artifact-signing.example.json'
    ExpectedPublisher = 'Company name'
}
Set-Content -LiteralPath $arguments.SignTool -Value "throw 'Signing tool must not be invoked by preflight tests.'"
Reject { & $signer @arguments -File $MiddlewareDll } 'Do not re-sign third-party libraries'
Reject { & $signer @arguments -File (Join-Path $RuntimeDirectory 'web-eid.exe') } 'Complete the Artifact Signing metadata'
$arguments.SigningMetadata = Join-Path $work 'metadata.json'
Set-Content -LiteralPath $arguments.SigningMetadata -Value '{"Endpoint":"https://weu.codesigning.azure.net","CodeSigningAccountName":"exampleaccount","CertificateProfileName":"exampleprofile"}'
# A vendor DLL renamed to our executable is still signed: refuse it before contacting Azure.
Copy-Item -LiteralPath $MiddlewareDll -Destination (Join-Path $work 'web-eid.exe')
Reject { & $signer @arguments -File (Join-Path $work 'web-eid.exe') } 'already contains a signature'
Write-Output 'Passed 5 signing preflight rejection cases. No signing request was sent.'
