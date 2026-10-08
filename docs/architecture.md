# Let's Peppol eID Bridge: first implementation slice

Status: experimental Windows x64 code and test tooling. The private-DLL signing
milestone and practical cancellation/card-removal checks passed on one clean
laptop, as reported by the user. Runtime/source selection and cross-project KYC
assurance evidence remain release items. No installer has been added.

The intended route remains the existing website -> web-eid.js -> upstream
extension -> Web eID native protocol -> libelectronic-id -> Belgian PKCS#11 ->
Windows PC/SC -> card. The backend remains responsible for KYC trust decisions.

The only runtime adaptation is in the libelectronic-id fork:

- Empty `ELECTRONIC_ID_BEID_MODULE_PATH`: keep upstream system middleware behavior.
- Explicit absolute local `.../beidpkcs11.dll`: use exactly that file for Belgian
  cards. Do not fall back if it is missing, corrupt or fails to initialize.
- Load that module through `LoadLibraryExW` with
  `LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32`.
  Convert separators before calling Windows. No CWD/PATH dependency search.
- Other countries, Linux/macOS, commands, algorithms and PIN interaction retain
  their upstream implementations.

An explicit build-time path is deliberately smaller than a general module
discovery framework. It also makes the PoC's source of middleware unambiguous.
Production must fix the destination beneath an administrator-protected directory
and verify its ACLs and parent directories; the current helper does not inspect
ACLs or make a developer's test directory suitable for production.

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

The upstream extension uses native host name `eu.webeid`. Keep it for the PoC;
installing two products that register this same host needs an explicit coexistence
design before packaging. No extension fork is justified yet. No website-only
origin restriction is implemented by this initial slice.
