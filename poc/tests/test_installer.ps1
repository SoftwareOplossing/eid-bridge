# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Msi)
$ErrorActionPreference = 'Stop'
$installer = New-Object -ComObject WindowsInstaller.Installer
$path = (Resolve-Path -LiteralPath $Msi).Path
$database = $installer.OpenDatabase($path, 0)
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
function Assert([bool]$condition, [string]$message) {
    if (-not $condition) { throw $message }
}
$properties = @{}
foreach ($row in Rows 'SELECT `Property`, `Value` FROM `Property`' 2) { $properties[$row[0]] = $row[1] }
Assert ($properties.ProductName -eq "Let's Peppol eID Bridge (Test)") 'Wrong product branding.'
Assert ($properties.UpgradeCode -eq '{B78C4195-034D-40D0-B28C-B0BC36B2D437}') 'Wrong upgrade identity.'
Assert ($properties.ALLUSERS -eq '1') 'Installer must use protected machine installation.'
Assert ($properties.ARPHELPLINK -eq 'https://be.letspeppol.org/onboarding' -and
    $properties.ARPURLINFOABOUT -eq 'https://be.letspeppol.org/onboarding') 'Wrong support link.'
foreach ($property in 'OWNINSTALLDIR','EXISTING_INSTALL_DIR','EXPECTEDHOST','EXPECTEDFIREFOXHOST','OSARCH','OSBUILD',
    'EDGE_EXTENSION_UPDATE','CHROME_EXTENSION_UPDATE','OWN_EDGE_EXTENSION_REQUEST','OWN_CHROME_EXTENSION_REQUEST') {
    Assert ($property -in ($properties.SecureCustomProperties -split ';')) "Property $property must survive elevation."
}
$logShortcut = @(Rows 'SELECT `Shortcut`, `Target`, `Arguments` FROM `Shortcut`' 3 | Where-Object { $_[0] -eq 'LogFolder' })
Assert ($logShortcut.Count -eq 1 -and $logShortcut[0][1] -eq '[WindowsFolder]explorer.exe' -and
    $logShortcut[0][2] -eq 'shell:Personal') 'Log shortcut must resolve the launching user, not the installer administrator.'
$registry = @(Rows 'SELECT `Registry`, `Root`, `Key`, `Name`, `Value`, `Component_` FROM `Registry`' 6)
$hosts = @($registry | Where-Object { $_[2] -like '*NativeMessagingHosts\eu.webeid' })
Assert ($hosts.Count -eq 6) 'Expected both registry views for three browsers.'
foreach ($hostRow in $hosts) {
    Assert ($hostRow[1] -eq '2') 'Native host registration must be machine-wide.'
    Assert ($hostRow[4] -like '[[]INSTALLFOLDER[]]eu.webeid*.json') 'Wrong manifest registration value.'
}
$requests = @($registry | Where-Object { $_[2] -match '^SOFTWARE\\(Microsoft\\Edge|Google\\Chrome)\\Extensions\\' })
Assert ($requests.Count -eq 2) 'Expected Edge and Chrome store installation requests.'
foreach ($request in $requests) {
    Assert ($request[1] -eq '2' -and $request[3] -eq 'update_url') 'Wrong external extension registration.'
    $expectedUrl = if ($request[2] -like '*Microsoft\Edge*') { 'https://edge.microsoft.com/extensionwebstorebase/v1/crx' } else { 'https://clients2.google.com/service/update2/crx' }
    Assert ($request[4] -eq $expectedUrl) 'Extension must come from the official browser store.'
}
Assert (@($registry | Where-Object { $_[2] -like 'SOFTWARE\Policies\*' }).Count -eq 0) 'Installer must not force-install extensions or introduce browser policies.'
$extensionComponents = @(Rows 'SELECT `Component`, `Attributes`, `Condition` FROM `Component`' 3 |
    Where-Object { $_[0] -in 'EdgeExtensionRequest','ChromeExtensionRequest' })
Assert ($extensionComponents.Count -eq 2) 'Missing extension components.'
foreach ($component in $extensionComponents) {
    Assert (([int]$component[1] -band 256) -eq 0 -and ([int]$component[1] -band 64) -eq 0) 'Store requests must use the 32-bit registry view and preserve their initial ownership.'
}
$searches = @(Rows 'SELECT `Signature_`, `Root`, `Key`, `Name`, `Type` FROM `RegLocator`' 5)
$hostSearches = @($searches | Where-Object { $_[2] -like '*NativeMessagingHosts\eu.webeid' })
Assert ($hostSearches.Count -eq 12) 'Both user/machine hives and registry views must be checked.'
$lock = @(Rows 'SELECT `LockObject`, `Table`, `SDDLText` FROM `MsiLockPermissionsEx`' 3)
Assert ($lock.Count -eq 1 -and $lock[0][0] -eq 'INSTALLFOLDER' -and $lock[0][1] -eq 'CreateFolder' -and
    $lock[0][2] -eq 'O:BAG:BAD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;BU)') 'Missing protected directory ACL.'
Assert (@(Rows 'SELECT `File` FROM `File`' 1).Count -gt 10) 'Runtime payload is incomplete.'

# Opening a package/evaluating conditions does not install it or change registry values.
$session = $installer.OpenPackage($path, 1)
function SetProperty([string]$name, [string]$value) {
    $null = $session.GetType().InvokeMember('Property', 'SetProperty', $null, $session, @($name,$value))
}
$hostCondition = @(Rows 'SELECT `Condition`, `Description` FROM `LaunchCondition`' 2 | Where-Object { $_[1] -like 'A different Web eID*' })[0][0]
$directoryCondition = @(Rows 'SELECT `Condition`, `Description` FROM `LaunchCondition`' 2 | Where-Object { $_[1] -like 'The installation folder*' })[0][0]
$osCondition = @(Rows 'SELECT `Condition`, `Description` FROM `LaunchCondition`' 2 | Where-Object { $_[1] -like 'This test installer requires*' })[0][0]
foreach ($browser in 'EDGE','CHROME') {
    $condition = ($extensionComponents | Where-Object { $_[0] -eq ($browser.Substring(0,1) + $browser.Substring(1).ToLowerInvariant() + 'ExtensionRequest') })[2]
    # A fresh request is owned; pre-existing requests are retained without ownership.
    SetProperty 'OWNINSTALLDIR' ''
    SetProperty "${browser}_EXTENSION_UPDATE" ''
    SetProperty "OWN_${browser}_EXTENSION_REQUEST" ''
    Assert ($session.EvaluateCondition($condition) -eq 1) 'Fresh extension request rejected.'
    $storeUrl = if ($browser -eq 'EDGE') { 'https://edge.microsoft.com/extensionwebstorebase/v1/crx' } else { 'https://clients2.google.com/service/update2/crx' }
    SetProperty "${browser}_EXTENSION_UPDATE" $storeUrl
    Assert ($session.EvaluateCondition($condition) -eq 0) 'Pre-existing request would be claimed.'
    SetProperty 'OWNINSTALLDIR' 'C:\Program Files\LetsPeppol eID Bridge\'
    Assert ($session.EvaluateCondition($condition) -eq 0) 'Upgrade would claim a previously unowned request.'
    SetProperty "OWN_${browser}_EXTENSION_REQUEST" '1'
    Assert ($session.EvaluateCondition($condition) -eq 1) 'Upgrade lost its owned request.'
    $sourceCondition = @(Rows 'SELECT `Condition`, `Description` FROM `LaunchCondition`' 2 | Where-Object { $_[1] -like "The Web eID $browser extension*" })[0][0]
    Assert ($session.EvaluateCondition($sourceCondition) -eq 1) 'Official extension store rejected.'
    SetProperty "${browser}_EXTENSION_UPDATE" 'https://other.example/update'
    Assert ($session.EvaluateCondition($sourceCondition) -eq 0) 'Unrelated extension source would be overwritten.'
    SetProperty "${browser}_EXTENSION_UPDATE" ''
    Assert ($session.EvaluateCondition($sourceCondition) -eq 1) 'Empty extension source rejected.'
}
foreach ($browser in 'EDGE','CHROME','FIREFOX') {
    foreach ($view in '32','64') {
        foreach ($hive in 'HKCU','HKLM') { SetProperty "HOST_${browser}_${view}_${hive}" '' }
    }
}
SetProperty 'OWNINSTALLDIR' ''
SetProperty 'EXISTING_INSTALL_DIR' ''
Assert ($session.EvaluateCondition($hostCondition) -eq 1) 'Clean registration state rejected.'
Assert ($session.EvaluateCondition($directoryCondition) -eq 1) 'Clean install directory rejected.'
SetProperty 'HOST_EDGE_64_HKCU' 'C:\LetsPeppolPoC\eu.webeid.json'
Assert ($session.EvaluateCondition($hostCondition) -eq 0) 'PoC registration would shadow installer.'
SetProperty 'HOST_EDGE_64_HKCU' ''
SetProperty 'HOST_CHROME_32_HKLM' 'C:\OtherApp\eu.webeid.json'
Assert ($session.EvaluateCondition($hostCondition) -eq 0) 'Other native host would be overwritten.'
SetProperty 'HOST_CHROME_32_HKLM' ''
SetProperty 'EXISTING_INSTALL_DIR' 'C:\Program Files\LetsPeppol eID Bridge\'
Assert ($session.EvaluateCondition($directoryCondition) -eq 0) 'Unknown existing directory accepted.'
SetProperty 'OWNINSTALLDIR' 'C:\Program Files\LetsPeppol eID Bridge\'
SetProperty 'EXPECTEDHOST' 'C:\Program Files\LetsPeppol eID Bridge\eu.webeid.json'
SetProperty 'EXPECTEDFIREFOXHOST' 'C:\Program Files\LetsPeppol eID Bridge\eu.webeid.firefox.json'
SetProperty 'HOST_EDGE_64_HKLM' 'C:\Program Files\LetsPeppol eID Bridge\eu.webeid.json'
Assert ($session.EvaluateCondition($hostCondition) -eq 1) 'Own upgrade registration rejected.'
Assert ($session.EvaluateCondition($directoryCondition) -eq 1) 'Own upgrade directory rejected.'
SetProperty 'Installed' '1'
SetProperty 'HOST_EDGE_64_HKLM' 'C:\OtherApp\eu.webeid.json'
Assert ($session.EvaluateCondition($hostCondition) -eq 0) 'Removal/maintenance could delete another host.'
SetProperty 'Installed' ''
SetProperty 'VersionNT64' '603'
SetProperty 'OSBUILD' '22000'
SetProperty 'OSARCH' 'AMD64'
Assert ($session.EvaluateCondition($osCondition) -eq 1) 'Supported Windows 11 x64 rejected.'
SetProperty 'OSBUILD' '19045'
Assert ($session.EvaluateCondition($osCondition) -eq 0) 'Unsupported Windows 10 accepted.'
SetProperty 'OSBUILD' '22000'
SetProperty 'OSARCH' 'ARM64'
Assert ($session.EvaluateCondition($osCondition) -eq 0) 'Untested ARM64 accepted.'
Write-Output 'MSI metadata, support links, extension ownership, ACL and conflict/upgrade/architecture conditions passed. No installation was performed.'
