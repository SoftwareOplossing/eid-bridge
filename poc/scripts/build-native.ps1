# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$QtPath,
    [Parameter(Mandatory)][string]$VcpkgRoot,
    [string]$BeidModulePath = '',
    [string]$BuildDirectory = '',
    [string]$CMake = 'cmake',
    [string]$Configuration = 'RelWithDebInfo'
)
$ErrorActionPreference = 'Stop'
$sourceDirectory = (Resolve-Path "$PSScriptRoot/../..").Path
if (-not $BuildDirectory) { $BuildDirectory = "$sourceDirectory/build/native-poc" }
if (-not (Test-Path "$QtPath/lib/cmake/Qt6/Qt6Config.cmake")) {
    throw 'QtPath must point to a Qt 6 MSVC x64 development kit.'
}
$toolchain = "$VcpkgRoot/scripts/buildsystems/vcpkg.cmake"
if (-not (Test-Path $toolchain)) { throw 'VcpkgRoot does not contain the vcpkg CMake toolchain.' }

& $CMake -S $sourceDirectory -B $BuildDirectory -A x64 `
    "-DCMAKE_PREFIX_PATH=$QtPath" "-DCMAKE_TOOLCHAIN_FILE=$toolchain" `
    "-DVCPKG_MANIFEST_DIR=$sourceDirectory/lib/libelectronic-id" `
    "-DELECTRONIC_ID_BEID_MODULE_PATH=$BeidModulePath"
if ($LASTEXITCODE -ne 0) { throw 'CMake configuration failed.' }
& $CMake --build $BuildDirectory --config $Configuration
if ($LASTEXITCODE -ne 0) { throw 'Native build failed.' }
$ctest = Join-Path (Split-Path (Get-Command $CMake).Source) 'ctest.exe'
& $ctest --test-dir $BuildDirectory -C $Configuration --output-on-failure
if ($LASTEXITCODE -ne 0) { throw 'Native tests failed.' }
