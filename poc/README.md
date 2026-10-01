# Windows x64 PoC

Start with the stock middleware/card baseline. The new private-path code is
prepared; full application build and hardware baseline are pending Windows CI
and a physical card test. Do not proceed to installer work until the
implementation plan's hardware and KYC gates pass.

The `Portable Windows x64 PoC` workflow builds a zip of the native application,
Qt/VC++/OpenSSL runtime files and instructions. It does **not** include Belgian
middleware, register a browser host, or install anything. Its app is compiled to
look for the test DLL at `C:/LetsPeppolPoC/beidpkcs11.dll`. Keep the clean PC free
of a global Belgian middleware installation. After the workflow succeeds, copy
its zip to that PC, extract it into `C:/LetsPeppolPoC`, and add an official x64
Belgian PKCS#11 DLL plus any independently verified dependencies there. The
stage remains an experiment, not a one-package installer. Confirm DLL provenance,
runtime dependencies and clean-machine absence before treating results as evidence.

Before copying the DLL to the clean PC, run the included
`clean-pc-preflight.ps1` there. It reports OS/architecture, smart-card service,
reader presence and two usual system DLL locations plus the ordinary middleware
uninstall entry. Share only this JSON result. These indicators do not prove the
machine is completely free of middleware or minidriver state; keep the original
clean-machine snapshot and inspect loaded modules during the test.

## Build and test the standalone probe

Requires CMake >=3.22 and a Windows C++ compiler. It needs no Qt, OpenSSL, Belgian
middleware or physical card to build or run its mock tests. With MSVC installed:

```powershell
cmake -S poc/native -B build/poc-native -A x64
cmake --build build/poc-native --config Release
ctest --test-dir build/poc-native -C Release --output-on-failure
```

On this development machine, the existing MinGW compiler was used with a local
CMake wheel installed beneath ignored `build/tools`:

```powershell
$env:PATH = 'C:\Ruby34-x64\msys64\ucrt64\bin;' + $env:PATH
& .\build\tools\cmake\data\bin\cmake.exe -S poc/native -B build/poc-native -G 'MinGW Makefiles'
& .\build\tools\cmake\data\bin\cmake.exe --build build/poc-native
& .\build\tools\cmake\data\bin\ctest.exe --test-dir build/poc-native --output-on-failure
```

Changing PATH here selects build tools. It is not middleware deployment or DLL
discovery. The loader explicitly excludes PATH when resolving private DLL imports.

## Baseline first

From an MSVC developer environment, install the Qt x64 development kit and use
vcpkg with the repository's pinned manifest. The wrapper builds/tests the native
application without invoking the upstream installer/WiX script:

```powershell
.\poc\scripts\build-native.ps1 -QtPath C:\Qt\6.11.2\msvc2022_64 -VcpkgRoot C:\vcpkg
python -m venv poc/.venv
.\poc\.venv\Scripts\python.exe -m pip install -r poc/requirements.txt
.\poc\.venv\Scripts\python.exe -m unittest discover -s poc/tests -v
.\poc\.venv\Scripts\python.exe poc/scripts/check-signature.py --app C:\LetsPeppol\eid-bridge\build\native-poc\src\app\RelWithDebInfo\web-eid.exe --origin https://localhost
```

Use the actual staging HTTPS origin when testing KYC. `https://localhost` above
labels an isolated CLI test; this script does not contact a website or register
a browser host. Ensure Qt/OpenSSL runtime DLLs are available beside the built
executable (Qt's `windeployqt`, plus the matching OpenSSL runtime). This wrapper
does not package or deploy those dependencies.

The checker retrieves the signing certificate and signs SHA-256 of the exact
ASCII bytes `Let's Peppol eID Bridge PoC\n`. Approve only this intended test and
enter the PIN in the native middleware UI. It verifies RSA PKCS#1 v1.5 or raw
P1363 ECDSA with the certificate public key, using a prehashed digest. It outputs
status, algorithm, digest and certificate SHA-256 fingerprint, not identity data.
Treat the fingerprint as linkable test evidence and keep it out of public logs.

This is mathematical signature verification, not certificate-chain/revocation,
Belgian nationality, legal identity, PDF or KYC verification. It does not discover
which DLL a running app loaded; confirm that separately with Process Monitor.

## Private runtime experiment, after baseline passes

Select an official x64 runtime with recorded binary hash, provenance and matching
source. Place it and required dependencies in a controlled test directory. Do not
copy the developer machine's system DLL into a release artifact.

Build a separate app directory with the fixed private module location:

```powershell
.\poc\scripts\build-native.ps1 -QtPath C:\Qt\6.11.2\msvc2022_64 -VcpkgRoot C:\vcpkg -BuildDirectory build/native-private -BeidModulePath 'C:/LetsPeppolPoC/beidpkcs11.dll'
.\build\poc-native\Release\beid-probe.exe C:\LetsPeppolPoC\beidpkcs11.dll --require-token
```

MinGW produces `build/poc-native/beid-probe.exe` without the `Release` directory.
Probe exits: 0 = requested checks passed; 1 = load/PKCS#11 failure; 2 = invalid
command; 3 = initialized/enumerated successfully but no token with `--require-token`.
Without that flag, zero tokens is a successful **load-only** result, never a card
or signing success. The probe never logs token labels, serials, certificates or PINs.

On a clean Windows VM with USB reader pass-through, establish absence of official
middleware/minidriver installation from the snapshot, registry, installed files
and module tracing. Record runtime prerequisites and all loaded modules. Repeat
the signature checker against the locally built private-path app, then the real
staging KYC flow and tamper tests. An explicit missing private DLL must fail even
if official middleware is also installed.

The module directory and parents must be administrator-protected before any
production use. The PoC loader does not validate ACLs. Pinpad dependencies and
middleware-internal loads still require tracing. A relocated DLL loading on a
machine with installed middleware is insufficient evidence of independence.
