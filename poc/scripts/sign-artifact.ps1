# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$File,
    [Parameter(Mandatory)][string]$SignTool,
    [Parameter(Mandatory)][string]$SigningDlib,
    [Parameter(Mandatory)][string]$SigningMetadata,
    [Parameter(Mandatory)][string]$ExpectedPublisher
)
$ErrorActionPreference = 'Stop'
$target = (Resolve-Path -LiteralPath $File).Path
$tool = (Resolve-Path -LiteralPath $SignTool).Path
$dlib = (Resolve-Path -LiteralPath $SigningDlib).Path
$metadataPath = (Resolve-Path -LiteralPath $SigningMetadata).Path
$name = [IO.Path]::GetFileName($target)
if ($name -ne 'web-eid.exe' -and $name -notmatch '^LetsPeppol-eID-Bridge-\d+\.\d+\.\d+-windows-x64-signed-candidate\.msi$') {
    throw 'Only our native application and installer may be signed. Do not re-sign third-party libraries.'
}
if ([string]::IsNullOrWhiteSpace($ExpectedPublisher)) { throw 'Specify the exact validated company publisher name.' }
$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
if ($metadata.Endpoint -notmatch '^https://[a-z]+\.codesigning\.azure\.net/?$' -or
    [string]::IsNullOrWhiteSpace($metadata.CodeSigningAccountName) -or
    [string]::IsNullOrWhiteSpace($metadata.CertificateProfileName) -or
    $metadata.CodeSigningAccountName -like 'REPLACE_*' -or $metadata.CertificateProfileName -like 'REPLACE_*') {
    throw 'Complete the Artifact Signing metadata with the approved account, Public Trust profile and regional endpoint.'
}
# Never override a vendor signature, or silently replace a previous company signature.
if ((Get-AuthenticodeSignature -LiteralPath $target).Status -ne 'NotSigned') {
    throw 'Use an unsigned build input; this file already contains a signature.'
}
& $tool sign /v /fd SHA256 /tr 'http://timestamp.acs.microsoft.com' /td SHA256 `
    /dlib $dlib /dmdf $metadataPath $target
if ($LASTEXITCODE -ne 0) { throw 'Artifact Signing failed. This artifact is not ready for delivery.' }
& $tool verify /pa /all /tw /v $target
if ($LASTEXITCODE -ne 0) { throw 'Signature or timestamp verification failed.' }
$signature = Get-AuthenticodeSignature -LiteralPath $target
if ($signature.Status -ne 'Valid' -or -not $signature.TimeStamperCertificate -or
    $signature.SignerCertificate.GetNameInfo([Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $false) -cne $ExpectedPublisher) {
    throw 'The signature must be valid, timestamped and issued to the expected company publisher.'
}
