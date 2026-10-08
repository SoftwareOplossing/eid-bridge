# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
# Run in a separate PowerShell process: this test remaps its HKCU/HKLM drives.
$ErrorActionPreference = 'Stop'
$testId = [guid]::NewGuid().ToString()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$buildRoot = Join-Path $repoRoot 'build'
$testDirectory = Join-Path $buildRoot "host-registration-$testId"
$testRegistryRoot = "Software\LetsPeppol-eID-Bridge-Tests\$testId"
$testKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("$testRegistryRoot\machine")
$testKey.Dispose()

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Expect-Failure([scriptblock]$Operation) {
    $failed = $false
    try { & $Operation | Out-Null } catch { $failed = $true }
    Assert $failed 'An operation that should be rejected succeeded.'
}

try {
    # All script registry paths now address only this GUID test namespace.
    Remove-PSDrive -Name HKCU, HKLM -Force
    New-PSDrive -Name HKCU -PSProvider Registry -Root "HKEY_CURRENT_USER\$testRegistryRoot" | Out-Null
    New-PSDrive -Name HKLM -PSProvider Registry -Root "HKEY_CURRENT_USER\$testRegistryRoot\machine" | Out-Null
    New-Item -ItemType Directory -Path $testDirectory -Force | Out-Null
    $helper = Join-Path $testDirectory 'register-test-host.ps1'
    Copy-Item -LiteralPath (Join-Path $repoRoot 'poc\scripts\register-test-host.ps1') -Destination $helper
    $app = Join-Path $testDirectory 'web-eid.exe'
    $dll = Join-Path $testDirectory 'beidpkcs11.dll'
    $manifestFile = Join-Path $testDirectory 'eu.webeid.letspeppol-poc.json'
    $edgeKey = 'HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\eu.webeid'

    Expect-Failure { & $helper -Action Install }
    Assert (-not (Test-Path -LiteralPath $edgeKey)) 'Missing binaries created a host key.'
    [System.IO.File]::WriteAllText($app, '')
    [System.IO.File]::WriteAllText($dll, '')

    & $helper -Action Install | Out-Null
    $status = & $helper -Action Status | ConvertFrom-Json
    Assert $status.registered_to_this_poc 'Normal installation failed.'
    $manifestText = Get-Content -LiteralPath $manifestFile -Raw
    $manifestData = $manifestText | ConvertFrom-Json
    Assert ($manifestData.path -eq $app -and $manifestData.name -eq 'eu.webeid' -and $manifestData.type -eq 'stdio') 'Wrong native host manifest.'
    Assert ($manifestData.allowed_origins.Count -eq 2) 'Unexpected extension allowlist.'
    Assert ((Get-Item -LiteralPath $edgeKey).GetValue('') -eq $manifestFile) 'Default registry value was not written.'
    & $helper -Action Install | Out-Null
    & $helper -Action Remove | Out-Null
    Assert (-not (Test-Path -LiteralPath $edgeKey)) 'Normal removal left the host key.'
    Assert (-not (Test-Path -LiteralPath $manifestFile)) 'Normal removal left the manifest.'

    # Reproduce the old helper's empty-key state and verify automatic repair.
    [System.IO.File]::WriteAllText($manifestFile, $manifestText)
    New-Item -Path $edgeKey -Force | Out-Null
    $status = & $helper -Action Status | ConvertFrom-Json
    Assert ($status.incomplete_registration -and -not $status.registration_conflict) 'Partial registration was not recognized.'
    & $helper -Action Install | Out-Null
    Assert ((& $helper -Action Status | ConvertFrom-Json).registered_to_this_poc) 'Partial registration repair failed.'
    & $helper -Action Remove | Out-Null

    # The same partial state must also support removal without installation.
    [System.IO.File]::WriteAllText($manifestFile, $manifestText)
    New-Item -Path $edgeKey -Force | Out-Null
    & $helper -Action Remove | Out-Null
    Assert (-not (Test-Path -LiteralPath $edgeKey)) 'Partial registration removal failed.'

    # An unrelated host must survive both attempted installation and removal.
    [System.IO.File]::WriteAllText($manifestFile, $manifestText)
    New-Item -Path $edgeKey -Force | Out-Null
    Set-Item -LiteralPath $edgeKey -Value 'C:\OtherProduct\host.json' -Type String
    Expect-Failure { & $helper -Action Install }
    Expect-Failure { & $helper -Action Remove }
    Assert ((Get-Item -LiteralPath $edgeKey).GetValue('') -eq 'C:\OtherProduct\host.json') 'Unrelated host was changed.'
    Remove-Item -LiteralPath $edgeKey

    # Empty keys carrying unrelated data are not the old helper's partial state.
    New-Item -Path $edgeKey -Force | Out-Null
    New-ItemProperty -LiteralPath $edgeKey -Name 'OtherProduct' -Value 'keep' | Out-Null
    Expect-Failure { & $helper -Action Install }
    Expect-Failure { & $helper -Action Remove }
    Remove-ItemProperty -LiteralPath $edgeKey -Name 'OtherProduct'
    & $helper -Action Remove | Out-Null

    # A failed write rolls back a newly created empty key.
    function Set-Item { throw 'Simulated registry write failure' }
    try { Expect-Failure { & $helper -Action Install } }
    finally { Remove-Item Function:\Set-Item }
    Assert (-not (Test-Path -LiteralPath $edgeKey)) 'Failed installation left an empty key.'
    & $helper -Action Install -Browser Chrome | Out-Null
    Assert ((& $helper -Action Status -Browser Chrome | ConvertFrom-Json).registered_to_this_poc) 'Chrome installation failed.'
    & $helper -Action Remove -Browser Chrome | Out-Null
    Write-Output 'PASS: install, repeat, repair, remove, conflicts, failed-write rollback, Chrome.'
} finally {
    Remove-PSDrive -Name HKCU, HKLM -Force -ErrorAction SilentlyContinue
    if ($testRegistryRoot -match '^Software\\LetsPeppol-eID-Bridge-Tests\\[0-9a-f-]{36}$') {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($testRegistryRoot, $false)
    }
    $resolvedTestDirectory = [System.IO.Path]::GetFullPath($testDirectory)
    $resolvedBuildRoot = [System.IO.Path]::GetFullPath($buildRoot) + [System.IO.Path]::DirectorySeparatorChar
    if ($resolvedTestDirectory.StartsWith($resolvedBuildRoot, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTestDirectory)) {
        Remove-Item -LiteralPath $resolvedTestDirectory -Recurse -Force
    }
}
