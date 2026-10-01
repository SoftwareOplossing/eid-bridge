# Belgian runtime investigation

No redistributable binary has been selected or bundled. Investigated middleware
source commit: `cf2d593181c56de33198993278d64990292772c1`.

The existing development machine contains signed x64
`C:/Windows/System32/beidpkcs11.dll`, file version `5.1.34.6213`, SHA-256
`b3e5bbd5112b5ef55f4189bdf334c989abf99f27c1cfb3c2a3e784efd780cf93`.
PowerShell reported a valid Authenticode signature by ZETES SA. This is an observed
baseline binary, not a provenance/source match for the inspected source HEAD.

On 2026-09-27, the compiled probe loaded this **system** DLL with the constrained
loader. `C_GetFunctionList`, `C_Initialize`, slot-count enumeration and
`C_Finalize` returned CKR_OK. Token count was zero. SCardSvr was running.
This proves neither signing nor private deployment nor clean-machine operation.

`objdump -p` found these direct import groups in that exact binary:

| Component | Required? | Evidence / scope | License status |
|---|---|---|---|
| beidpkcs11.dll x64 | Initial candidate | Explicit PKCS#11 entry point; private application directory planned | Upstream LGPL-3.0-or-later; exact binary/source mapping pending |
| WinSCard, USER32, GDI32, ADVAPI32, SHELL32, KERNEL32 | Direct imports | Windows supplied; do not copy them into the bundle | OS components |
| MSVCP140, VCRUNTIME140, VCRUNTIME140_1 | Direct imports | VC++ runtime deployment must be determined for clean Windows | Microsoft redistribution terms must be checked for selected distribution |
| api-ms-win-crt runtime/stdio/string/heap/filesystem/convert/time | Direct imports | Universal CRT API sets; OS resolution must be checked | OS/runtime components |
| Additional middleware DLLs/resources | Unresolved | Direct imports do not reveal delayed or explicit runtime loads | Audit selected artifacts |
| beidpp pinpad helpers | Unresolved for pinpad readers | `cardcomm/pkcs11/src/cardlayer/pinpadlib.cpp` searches System32/beidpp | Audit if included |
| Minidriver | Unproven requirement | PKCS#11 project links WinSCard; this does not establish card operation without minidriver registration | Do not install as a workaround |
| Viewer, Firefox integration, shell utilities, x86/ARM64 payloads | Not selected | Outside initial x64 CCID experiment unless evidence requires them | Excluded for now |

Source checks: `cardcomm/pkcs11/VS_2022/beidpkcs11.vcxproj` contains Windows
smart-card/UI/system imports and dynamic VC runtime configuration.
`src/common/configreg.cpp` accesses middleware registry settings and has fallback
handlers. `src/common/dynamiclib.cpp` and `src/cardlayer/pinpadlib.cpp` contain
additional dynamic-loading behavior. Their presence is an investigation item,
not proof of mandatory global installation or of safe private operation.

Next evidence: select reproducible official binary/source pair; inspect complete
transitive dependencies; trace initialization/PIN/signing on clean Windows with
no middleware/minidriver; test ordinary CCID readers first. Do not infer registry
independence or minimum bundle size from source/import tables alone.
