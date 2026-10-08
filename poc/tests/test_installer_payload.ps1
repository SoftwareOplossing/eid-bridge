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
if ($build.module_resolution -ne 'APP_DIRECTORY' -or
    (Get-FileHash -LiteralPath (Join-Path $output 'web-eid.exe') -Algorithm SHA256).Hash -ne $build.app_sha256) {
    throw 'Extracted application differs from verified installer build.'
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
