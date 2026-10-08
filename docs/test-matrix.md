# Validation status

Initial run: Windows development host, 2026-09-27. CMake 3.31.6 / MinGW GCC 15.2.0;
Python 3.13 / cryptography 50.0.1. Hardware baseline added 2026-10-01 with an
inserted Belgian eID. No PIN or identifying certificate data is recorded here.

Clean physical laptop report, 2026-10-04: Windows 11 Home x64 (10.0.26300),
internal card reader and optional external USB reader. The user's preflight
reported smart-card service running and no Belgian DLL in System32/SysWOW64 or
Belgian middleware uninstall entry. These checks do not rule out every driver,
registry setting or previously installed component. The local PoC archive used
the fixed `C:/LetsPeppolPoC/beidpkcs11.dll` path. The reported certificate
fingerprint is intentionally omitted from this repository.

| Check | Result | Evidence / next action |
|---|---|---|
| Standalone native probe compilation | PASS | `cmake --build build/poc-native` |
| Native automated suite | PASS, 8 CTest cases | Mock enumeration, required-token failure, missing export, relative path rejection; default/private resolution, sibling dependency success, CWD/PATH dependency exclusion, eleven configuration inputs (valid configurations also compiled) |
| Independent signature checker | PASS, 11 unittest cases | Synthetic RSA/ECC, altered digest/signature, substituted cert, wrong algorithm, malformed ECC, native errors/timeout and privacy-safe route detection |
| Browser-host helper | PASS locally, 2026-10-08 | Windows PowerShell actual writes in isolated registry drives: installation/repeat/removal, partial-state recovery, unrelated-host protection and write-failure rollback. First helper's read-only-handle defect fixed. |
| Native browser startup handshake | PASS locally, 2026-10-08 | Existing portable logging build returned framed version `2.11.0+0` with the Edge extension origin and `--parent-window=0`; no card or PIN required. The subsequent clean-laptop browser check was reported working after host repair. |
| Installed system middleware load/init | PASS, baseline only | Signed version 5.1.34.6213; PKCS#11 init/enumeration returned CKR_OK with one token after card insertion |
| Full native build | PASS in Windows CI | Portable Windows x64 PoC workflow built and ran tests; archive included MSVC runtime and was hash-verified after extraction |
| T1 stock app + system middleware + card | PASS, preliminary | Installed Web eID 2.8.0 retrieved the signing certificate and signed the fixed SHA-256 digest; independent RSA PKCS#1 v1.5 verification passed after private PIN entry. Repeat on the plan's pinned version before final gate. |
| T2 current staging KYC | NOT RUN | Trace existing backend acceptance and redacted evidence |
| POC-1 private DLL on clean Windows | PASS, user-reported | Private DLL loaded; `C_GetFunctionList`, `C_Initialize`, slot enumeration and `C_Finalize` returned CKR_OK with the system DLL absent. Loaded-module trace still needed. |
| POC-2 Belgian token | PASS, user-reported | With the card inserted, private-DLL probe returned `tokens_present=1`, `C_GetTokenInfo=CKR_OK`, and exit code 0. The earlier zero-token/exit-3 result was with the card absent. Token identity is not logged. |
| POC-3 signing certificate | PASS, preliminary | Private-path Web eID retrieved a parseable signing certificate used for successful signature verification. The route-only diagnostic reported `belgian-pkcs11` and `certificate_retrieved=true`. Card ownership/subject and chain trust were not independently checked. |
| POC-4 PIN signature and verification | PASS, happy path | One initial native request failed; three later runs produced independently verified RSA/SHA-256 PKCS#1 v1.5 signatures after local PIN entry. Wrong PIN/cancellation not tested; do not automate PIN attempts. |
| POC-5 removal/reinsertion | PARTIAL | User reattached USB reader and subsequent signing continued. Removal before/during operation and recovery are untested. |
| Native KYC contract signing | PASS, user-reported, 2026-10-08 | User reports signing and successful KYC/registration for the intended company and director, with a downloaded final PDF |
| Downloaded KYC PDF integrity | PASS, user-reported, 2026-10-08 | One signature; intact signed bytes, valid cryptographic signature and whole-file coverage all true. Targeted xref compatibility used; original parsing restriction confirmed |
| KYC certificate trust/identity/account binding | NOT INDEPENDENTLY VERIFIED | Site success reported for intended company/director; deployed chain/revocation policy and intended-document/account binding remain to be verified |
| PDFBox/iText checker compatibility | PASS locally, synthetic evidence | Original compressed backend reproduction passes signature/whole-file checks using the targeted fallback; earlier local KYC workaround removed. No website deployment needed for the checker |
| Offline PDF checker | PASS locally, 15 cases | Strict and compressed xref-reuse PDFs; altered content/CMS, unsigned documents and later updates fail. Other strict errors and encrypted fallback input are rejected; private payloads omitted |
| Edge onboarding certificate check | PASS, user-reported, 2026-10-08 | User confirmed the prescribed retry works after installing the corrected host helper, with the official extension and existing private-DLL PoC. Signing and intended company/director KYC/registration subsequently reported working. |
| Chrome/Firefox browser integration | NOT RUN | Edge result does not establish other-browser support |

The initial clean-Windows private-DLL signing milestone is **met**: the module
loaded, a token was enumerated, Web eID selected the Belgian PKCS#11 route,
retrieved a certificate and returned independently verified signatures. Formal
Gate A sign-off still needs loaded-module/dependency evidence and the remaining
POC-4 negative case. Gate B
(actual KYC assurance) is **not passed**. The mathematical signature checker tests
neither PDF trust nor CA trust/revocation. Windows 10, ARM64, Linux and macOS
have no support claim.

Remaining negative/manual matrix: absent reader/card, unsupported card, wrong or
blocked PIN, cancellation, removal, expired/revoked cert, two readers/cards, missing
or corrupt private DLL despite installed middleware, changed PDF/signature/digest,
substituted certificate/finalization reference, replay/cross-account submission,
client-provided wrong name, unsupported browser and multiple card generations.
Use a disposable test card for retry-exhaustion tests with human supervision.

Both Windows CI workflows passed remotely. The application pins the published
library patch so a fresh checkout can run the tests. The private-DLL test archive
contains the MSVC runtime; it is a controlled PoC, not a redistributable release.
