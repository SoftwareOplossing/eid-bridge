# Let's Peppol eID Bridge: first implementation slice

Status: experimental Windows x64 code and test tooling. The private-DLL signing
milestone and practical cancellation/card-removal checks passed on one clean
laptop, as reported by the user. Runtime/source selection and cross-project KYC
assurance evidence remain release items. A private Windows 11 x64 test MSI
now packages the native bridge, runtime DLLs and tested Belgian module.

The intended route remains the existing website -> web-eid.js -> upstream
extension -> Web eID native protocol -> libelectronic-id -> Belgian PKCS#11 ->
Windows PC/SC -> card. The backend remains responsible for KYC trust decisions.

The only runtime adaptation is in the libelectronic-id fork:

- Empty `ELECTRONIC_ID_BEID_MODULE_PATH`: keep upstream system middleware behavior.
- Explicit absolute local `.../beidpkcs11.dll`: use exactly that file for Belgian
  cards. Do not fall back if it is missing, corrupt or fails to initialize.
- `APP_DIRECTORY`: resolve `beidpkcs11.dll` beside the running executable using
  `GetModuleFileNameW`. The installer uses this option under Program Files;
  moving the portable PoC directory is no longer required.
- Load that module through `LoadLibraryExW` with
  `LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32`.
  Convert separators before calling Windows. No CWD/PATH dependency search.
- Other countries, Linux/macOS, commands, algorithms and PIN interaction retain
  their upstream implementations.

An explicit build-time path is deliberately smaller than a general module
discovery framework. It also makes the PoC's source of middleware unambiguous.
The test MSI fixes the destination at Program Files\LetsPeppol eID Bridge and
sets a protected ACL: SYSTEM/Administrators full access, Users read/execute.
It refuses an existing directory without its own installation marker. The PoC
helper does not make a developer's test directory suitable for production.

Windows loader flags constrain static dependency resolution. They do not sandbox
middleware code, override already loaded dependency modules, or control later
`LoadLibrary` calls made inside middleware. The successful clean-install test
establishes practical dependency sufficiency for the tested package; tracing is
available for diagnosing unexpected loads during release engineering.
[Windows loader reference](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-loadlibraryexw).

The native probe shares the library loader and calls `C_GetFunctionList`,
`C_Initialize`, slot/token enumeration and `C_Finalize`, without PIN or identity
output. The separate Python check exercises the real native application's signing
protocol and verifies RSA PKCS#1 v1.5 or raw ECDSA signatures independently.

The upstream extension uses native host name `eu.webeid`. The test MSI keeps it
and registers machine hosts for Edge/Chrome/Firefox in both registry views.
It refuses conflicts in the installing user's HKCU and machine HKLM views,
including an existing PoC registration; another user's HKCU is not inspected.
Two native applications owning the same host are not supported. No extension
fork is justified yet. No website-only origin restriction is implemented.

MSI 0.1.1 reuses upstream's Edge/Chrome external extension store requests. Browser
confirmation is retained, and Firefox still uses a manual store install. Requests
that predate this MSI are not claimed or removed. No forced browser policy is
introduced, and no third-party extension is blocked. Native and Windows help
links point to Let's Peppol onboarding.

The installer authoring is separate from upstream `install/web-eid.wxs`, with
its own product/upgrade identity. MSI manages files, registrations, shortcuts,
upgrade rollback and uninstall; no registration PowerShell custom action is used.
Logging and Let's Peppol branding are the other small application adaptations.
