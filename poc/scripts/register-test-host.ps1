# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
param(
    [ValidateSet('Install', 'Status', 'Remove')]
    [string]$Action = 'Status',
    [ValidateSet('Edge', 'Chrome')]
    [string]$Browser = 'Edge'
)

$ErrorActionPreference = 'Stop'

# PoC only: run this copy from C:\LetsPeppolPoC alongside web-eid.exe.
$appPath = Join-Path $PSScriptRoot 'web-eid.exe'
$manifestPath = Join-Path $PSScriptRoot 'eu.webeid.letspeppol-poc.json'
$hostName = 'eu.webeid'
$registryKey = if ($Browser -eq 'Edge') {
    "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$hostName"
} else {
    "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$hostName"
}
$otherRegistrations = @(
    "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$hostName"
    "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$hostName"
    "HKLM:\Software\Microsoft\Edge\NativeMessagingHosts\$hostName"
    "HKLM:\Software\Google\Chrome\NativeMessagingHosts\$hostName"
    "HKLM:\Software\WOW6432Node\Microsoft\Edge\NativeMessagingHosts\$hostName"
    "HKLM:\Software\WOW6432Node\Google\Chrome\NativeMessagingHosts\$hostName"
)
$manifest = [ordered]@{
    name = $hostName
    description = "Let's Peppol eID Bridge test host"
    path = $appPath
    type = 'stdio'
    allowed_origins = @(
        'chrome-extension://gnmckgbandlkacikdndelhfghdejfido/'
        'chrome-extension://ncibgoaomkmdpilpocfeponihegamlic/'
    )
}
$manifestJson = $manifest | ConvertTo-Json -Depth 3

function Get-HostValue([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return (Get-Item -LiteralPath $Path).GetValue('')
}

function Test-OwnManifest {
    if (-not (Test-Path -LiteralPath $manifestPath)) { return $false }
    return ((Get-Content -LiteralPath $manifestPath -Raw) -eq $manifestJson)
}

$existing = @($otherRegistrations | Where-Object { Test-Path -LiteralPath $_ })
$ownRegistration = (Get-HostValue $registryKey) -eq $manifestPath -and (Test-OwnManifest)

switch ($Action) {
    'Status' {
        [pscustomobject]@{
            browser = $Browser
            registered_to_this_poc = [bool]$ownRegistration
            registration_conflict = [bool]($existing.Count -gt 0 -and -not ($existing.Count -eq 1 -and $ownRegistration))
            app_present = Test-Path -LiteralPath $appPath
            private_dll_present = Test-Path -LiteralPath (Join-Path $PSScriptRoot 'beidpkcs11.dll')
        } | ConvertTo-Json
        break
    }
    'Install' {
        if (-not (Test-Path -LiteralPath $appPath)) { throw "web-eid.exe is missing beside this script." }
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'beidpkcs11.dll'))) {
            throw "beidpkcs11.dll is missing beside this script."
        }
        if ($existing.Count -gt 0 -and -not ($existing.Count -eq 1 -and $ownRegistration)) {
            throw "A Web eID native host is already registered. No registration was changed."
        }
        if (Test-Path -LiteralPath $manifestPath) {
            if (-not (Test-OwnManifest)) { throw "An existing test manifest would be overwritten. No registration was changed." }
        } else {
            [System.IO.File]::WriteAllText($manifestPath, $manifestJson, [System.Text.UTF8Encoding]::new($false))
        }
        if (-not $ownRegistration) {
            New-Item -Path $registryKey -Force | Out-Null
            (Get-Item -LiteralPath $registryKey).SetValue('', $manifestPath, [Microsoft.Win32.RegistryValueKind]::String)
        }
        Write-Output "Registered $hostName for $Browser in the current user's profile."
        break
    }
    'Remove' {
        if (Test-Path -LiteralPath $registryKey) {
            if (-not $ownRegistration) { throw "The registration or manifest differs from this PoC. Nothing was removed." }
            Remove-Item -LiteralPath $registryKey
        }
        if (Test-Path -LiteralPath $manifestPath) {
            if (-not (Test-OwnManifest)) { throw "The test manifest differs from this PoC. Nothing was removed." }
            Remove-Item -LiteralPath $manifestPath
        }
        Write-Output "Removed this PoC host registration for $Browser."
        break
    }
}
