# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$os = Get-CimInstance Win32_OperatingSystem
$service = Get-Service SCardSvr -ErrorAction SilentlyContinue
$readerCount = @(Get-PnpDevice -Class SmartCardReader -PresentOnly -ErrorAction SilentlyContinue).Count
$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$installedMiddleware = @(Get-ItemProperty $uninstallRoots -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match '^Belgium e-ID middleware' }).Count -gt 0

# This is intentionally a small checklist, not a proof of all installation state.
# No card contents, reader serial numbers, PIN or Windows user identifiers are read.
[ordered]@{
    os = $os.Caption
    os_version = $os.Version
    architecture = $os.OSArchitecture
    smart_card_service = if ($service) { [string]$service.Status } else { 'Not found' }
    reader_present = ($readerCount -gt 0)
    system_beidpkcs11_present = (Test-Path "$env:WINDIR\System32\beidpkcs11.dll")
    syswow64_beidpkcs11_present = (Test-Path "$env:WINDIR\SysWOW64\beidpkcs11.dll")
    installed_middleware_entry_present = $installedMiddleware
} | ConvertTo-Json
