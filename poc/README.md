# Windows x64 PoC

The stock Web eID 2.8.0 application signed the fixed test digest with an inserted
Belgian eID through installed middleware on 2026-10-01; independent RSA/SHA-256
verification passed. On 2026-10-04, the private-path build also produced three
independently verified signatures on a clean Windows 11 x64 laptop without the
Belgian middleware uninstall entry or the usual system DLLs. A repeat private-DLL
probe with the card inserted found one token and exited successfully. The
route-only diagnostic reported `belgian-pkcs11` for certificate retrieval.
Loaded-module tracing, negative hardware tests, exact binary source
correspondence and real KYC remain open. Do not proceed to installer
work until the implementation plan's gates pass.

The `Portable Windows x64 PoC` workflow builds a zip of the native application,
Qt/VC++/OpenSSL runtime files and instructions. It does **not** include Belgian
middleware, register a browser host, or install anything. Its app is compiled to
look for the test DLL at `C:/LetsPeppolPoC/beidpkcs11.dll`. Keep the clean PC free
of a global Belgian middleware installation. After the workflow succeeds, copy
its zip to that PC, extract it into `C:/LetsPeppolPoC`, and add an official x64
Belgian PKCS#11 DLL plus any independently verified dependencies there. The
stage remains an experiment, not a one-package installer. Confirm DLL provenance,
runtime dependencies and clean-machine absence before treating results as evidence.

## Browser check on the clean laptop

The current [Let's Peppol onboarding page](https://be.letspeppol.org/onboarding)
has a **Check Web eID** button. Its source calls `getSigningCertificate` and
shows a success state if it obtains a signing certificate and SHA-256 support.
It does not submit a KYC contract or require a PIN. This is a browser/native-host
integration check only; do not start real registration or contract signing for
this PoC.

On the clean Windows laptop, install the official [Web eID extension for
Edge](https://microsoftedge.microsoft.com/addons/detail/gnmckgbandlkacikdndelhfghdejfido)
through Edge Add-ons and ensure it is enabled. No extension fork is needed for
this check. Keep the portable native app and private Belgian DLL in
`C:\LetsPeppolPoC`. Copy `register-test-host.ps1` beside `web-eid.exe` and run:

```powershell
cd C:\LetsPeppolPoC
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\register-test-host.ps1 -Action Status
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\register-test-host.ps1 -Action Install
```

The script registers `eu.webeid` under **HKCU for Edge only** and creates a
manifest that points to this exact portable app. It refuses to replace an
existing Web eID native-host registration and requires the private DLL to be
present. If it reports a conflict, stop and report that status; do not manually
override the existing host. Restart Edge, open the onboarding URL, insert the
card, and click **Check Web eID**. Share only whether the page shows **Web eID
is working** or an error message, without certificate, identity or PIN data.
After the check, remove this test registration with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\register-test-host.ps1 -Action Remove
```

The 2026-10-08 helper fixes a registry write failure in the first version.
`Get-Item` returned a read-only registry handle, so its `SetValue` call left an
empty key and a valid PoC manifest. The corrected helper uses `Set-Item` and
can repair that exact partial state by rerunning `-Action Install`, or clean it
up with `-Action Remove`. Use normal PowerShell under the same Windows user
who runs Edge; administrator privileges are unnecessary. Other registrations
and empty keys carrying unrelated values or subkeys remain protected.

The helper's Windows PowerShell regression test remaps HKCU/HKLM drives to a
temporary GUID registry namespace. It exercises actual default-value writes,
repeat installation, partial-state repair/removal, conflicts and failed-write
rollback without touching real browser registrations:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\poc\tests\test_host_registration.ps1
```

This is not the production one-package installer. The extension currently
comes from the browser store; its installation/activation behavior must be
resolved for release. The live onboarding check does not prove the backend KYC
validation gates.

The Windows fork writes an operational log by default at
`Documents/LetsPeppol eID Bridge/Logs/LetsPeppol-eID-Bridge.log`, with one
rotated previous file on the next launch after it reaches 5 MiB. No registry key
or `web-eid.conf` flag is required. Logs can include card/reader and error details; review them
before sharing and never include a PIN or raw certificate.

Before copying the DLL to the clean PC, run the included
`clean-pc-preflight.ps1` there. It reports OS/architecture, smart-card service,
reader presence and two usual system DLL locations plus the ordinary middleware
uninstall entry. Share only this JSON result. These indicators do not prove the
machine is completely free of middleware or minidriver state; keep the original
clean-machine snapshot and inspect loaded modules during the test.

On a development PC that already has the official middleware, use
`stage-test-middleware.ps1 -ExpectedSha256 <recorded SHA-256>` to make a **local**
test kit from its signed DLL, the probe and LGPL notice. It checks the expected
hash/signature and writes the kit under ignored `build/`. Do not commit or publish
that binary or treat its unknown exact source correspondence as release-ready.

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
.\poc\.venv\Scripts\python.exe -m pip install -r poc/pdf-requirements.txt
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

To determine whether signing uses the intended Belgian PKCS#11 route or Web
eID's Windows CryptoAPI fallback, run the same checker with `--route-only` and
the same `--app` / `--origin` arguments. It retrieves a certificate without PIN
entry, reads the native app's diagnostic stderr through a pipe, and prints only
`card_route` and `certificate_retrieved`. It never prints the certificate or
reader name. `belgian-pkcs11` is the expected route for this experiment;
`windows-cryptoapi` is a different backend and does not prove private-DLL
signing. Run with a correctly seated card.

This is mathematical signature verification, not certificate-chain/revocation,
Belgian nationality, legal identity, PDF or KYC verification. It does not discover
which DLL a running app loaded; confirm that separately with Process Monitor.

## Check the downloaded KYC PDF privately

After the website finishes contract signing, keep the downloaded PDF on the
test laptop and run the separate offline checker:

```powershell
.\check-kyc-pdf.exe 'C:\path\to\signed-contract.pdf'
```

Its JSON contains booleans, a signature count and static parsing status. It reports whether the
signed bytes are intact, the CMS signature verifies, and the entire file is
covered. `integrity_check_passed=true` requires exactly one regular signature
and all three checks. Later legitimate signatures/timestamps/updates may need
review; a coverage failure alone does not prove malicious tampering.
No certificate identity, PDF content, filename or fingerprint is printed.
The checker tries strict parsing first. For the specific xref stream reuse
restriction reproduced in compressed PDFBox/iText contracts, it retries with
the compatibility reader on the same bytes. Its output then includes
`pdf_parse_mode=xref_compatibility` and `parser_issue=xref_stream_object_reused`;
otherwise `pdf_parse_mode=strict` is reported. All signature and coverage checks
still apply. Encrypted PDFs are unsupported by the fallback, and other strict
errors remain failures (`strict_pdf_structure_rejected`). See
[the reproduction and compatibility evidence](../docs/kyc-validation-report.md#pdf-interoperability-reproduction-and-checker-compatibility).
Existing contracts can be checked without changing or re-signing them.
The source version runs as `python poc/scripts/check-kyc-pdf.py <pdf>` using
`poc/pdf-requirements.txt`. No HTTP/certificate-fetching requests are enabled.

This checker has no configured Belgian trust anchors and does not prove CA
trust, revocation, the intended contract, director identity or account binding.
Those explicit false fields are remaining assurance checks, not a claim that
the certificate is invalid. Share only the JSON; retain the PDF privately.

Packaging uses PyInstaller 6.19.0 with `--onefile --console`, and
`--collect-all pyhanko --collect-all pyhanko_certvalidator --collect-all tzdata`.
The local test zip includes dependency license notices. This diagnostic is
separate from the native bridge and does not add runtime dependencies to it.

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

On a clean Windows PC, establish absence of official
middleware/minidriver installation from the snapshot, registry, installed files
and module tracing. Record runtime prerequisites and all loaded modules. Repeat
the signature checker against the locally built private-path app, then the real
staging KYC flow and tamper tests. An explicit missing private DLL must fail even
if official middleware is also installed.

The module directory and parents must be administrator-protected before any
production use. The PoC loader does not validate ACLs. Pinpad dependencies and
middleware-internal loads still require tracing. A relocated DLL loading on a
machine with installed middleware is insufficient evidence of independence.
