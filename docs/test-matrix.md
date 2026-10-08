# Validation status

Initial run: Windows development host, 2026-09-27. CMake 3.31.6 / MinGW GCC 15.2.0;
Python 3.13 / cryptography 50.0.1. Hardware baseline added 2026-10-01 with an
inserted Belgian eID. No PIN or identifying certificate data is recorded here.

Clean physical laptop report, 2026-10-04: Windows 11 Home x64 (10.0.26300),
internal card reader and optional external USB reader. The user's preflight
reported smart-card service running and no Belgian DLL in System32/SysWOW64 or
Belgian middleware uninstall entry. These checks do not rule out every driver,
registry setting or previously installed component. The clean-install report
and successful operations are accepted as practical dependency evidence for
this Windows x64 PoC. No additional module trace is requested from the tester.
The local PoC archive used
the fixed `C:/LetsPeppolPoC/beidpkcs11.dll` path. The reported certificate
fingerprint is intentionally omitted from this repository.

| Check | Result | Evidence / next action |
|---|---|---|
| Standalone native probe compilation | PASS | `cmake --build build/poc-native` |
| Native automated suite | PASS, 9 CTest cases | Mock enumeration, required-token failure, missing export, relative path rejection; default/private/executable-directory resolution, sibling dependency success, CWD/PATH dependency exclusion, twelve configuration inputs (valid configurations also compiled) |
| Independent signature checker | PASS, 11 unittest cases | Synthetic RSA/ECC, altered digest/signature, substituted cert, wrong algorithm, malformed ECC, native errors/timeout and privacy-safe route detection |
| Browser-host helper | PASS locally, 2026-10-08 | Windows PowerShell actual writes in isolated registry drives: installation/repeat/removal, partial-state recovery, unrelated-host protection and write-failure rollback. First helper's read-only-handle defect fixed. |
| Native browser startup handshake | PASS locally, 2026-10-08 | Existing portable logging build returned framed version `2.11.0+0` with the Edge extension origin and `--parent-window=0`; no card or PIN required. The subsequent clean-laptop browser check was reported working after host repair. |
| Installed system middleware load/init | PASS, baseline only | Signed version 5.1.34.6213; PKCS#11 init/enumeration returned CKR_OK with one token after card insertion |
| Full native build | PASS in Windows CI | Portable Windows x64 PoC workflow built and ran tests; archive included MSVC runtime and was hash-verified after extraction |
| T1 stock app + system middleware + card | PASS, preliminary | Installed Web eID 2.8.0 retrieved the signing certificate and signed the fixed SHA-256 digest; independent RSA PKCS#1 v1.5 verification passed after private PIN entry. Repeat on the plan's pinned version before final gate. |
| T2 current staging KYC | NOT RUN | Trace existing backend acceptance and redacted evidence |
| POC-1 private DLL on clean Windows | PASS, user-reported | Private DLL loaded; `C_GetFunctionList`, `C_Initialize`, slot enumeration and `C_Finalize` returned CKR_OK with the system DLL absent. Clean-install signing/browser/PDF results establish practical dependency sufficiency for the tested package. |
| POC-2 Belgian token | PASS, user-reported | With the card inserted, private-DLL probe returned `tokens_present=1`, `C_GetTokenInfo=CKR_OK`, and exit code 0. The earlier zero-token/exit-3 result was with the card absent. Token identity is not logged. |
| POC-3 signing certificate | PASS, preliminary | Private-path Web eID retrieved a parseable signing certificate used for successful signature verification. The route-only diagnostic reported `belgian-pkcs11` and `certificate_retrieved=true`. Card ownership/subject and chain trust were not independently checked. |
| POC-4 PIN signature and verification | PASS, happy path | One initial native request failed; three later runs produced independently verified RSA/SHA-256 PKCS#1 v1.5 signatures after local PIN entry. Cancellation separately reported tested on 2026-10-08; wrong-PIN behavior is not claimed. |
| Native cancellation | PASS, user-reported, 2026-10-08 | User reports cancellation already tested in response to the proposed failure/retry check; detailed dialog/timing evidence was not collected. No repeat requested. |
| POC-5 card removal/reinsertion | PASS, user-reported, 2026-10-08 | User reports card removal already tested in response to the proposed removal/recovery check. Earlier reader reattachment/signing also worked. Exact removal timings were not collected; no repeat requested. |
| Native KYC contract signing | PASS, user-reported, 2026-10-08 | User reports signing and successful KYC/registration for the intended company and director, with a downloaded final PDF |
| Downloaded KYC PDF integrity | PASS, user-reported, 2026-10-08 | One signature; intact signed bytes, valid cryptographic signature and whole-file coverage all true. Targeted xref compatibility used; original parsing restriction confirmed |
| KYC certificate trust/identity/account binding | NOT INDEPENDENTLY VERIFIED | Site success reported for intended company/director; deployed chain/revocation policy and intended-document/account binding remain to be verified |
| PDFBox/iText checker compatibility | PASS locally, synthetic evidence | Original compressed backend reproduction passes signature/whole-file checks using the targeted fallback; earlier local KYC workaround removed. No website deployment needed for the checker |
| Offline PDF checker | PASS locally, 15 cases | Strict and compressed xref-reuse PDFs; altered content/CMS, unsigned documents and later updates fail. Other strict errors and encrypted fallback input are rejected; private payloads omitted |
| Edge onboarding certificate check | PASS, user-reported, 2026-10-08 | User confirmed the prescribed retry works after installing the corrected host helper, with the official extension and existing private-DLL PoC. Signing and intended company/director KYC/registration subsequently reported working. |
| Chrome/Firefox browser integration | NOT RUN | Edge result does not establish other-browser support |
| Installer native application | PASS, Windows CI run 37826961112 | Branded app with APP_DIRECTORY module resolution, app commit 23545f44ad4bc9d70396f72ddc786488efdf839a and library 2f1cffc9b99919c8172405ca265f28a7cb8caee7; runtime artifact hashes verified locally |
| Private MSI compilation | PASS locally | WiX 4.0.6 build and MSI validation; separate product/upgrade identity and protected Program Files target |
| MSI registration/upgrade/removal conditions | PASS locally | Windows PowerShell 5.1 reads actual MSI tables and evaluates clean install, PoC/other-host conflicts, own upgrade, changed host during removal, unknown existing folder and Windows/architecture conditions; no installation performed |
| MSI packaged payload | PASS locally | All 83 actual CAB files checked against installed hash manifest; native build metadata and browser manifests verified independently through MSI file/directory tables |
| MSI extracted app startup/logging | PASS locally | Framed version 2.11.0+0 and quit responses; automatic current-user Documents log updated; no card/PIN used |
| MSI 0.1.0 physical install/uninstall | PASS, user-reported | User confirmed installation/uninstallation works; no detailed Windows Installer log was collected. Upgrade not yet tested |
| MSI 0.1.1 extension request authoring | PASS locally | Actual MSI registry tables and conditions: official Edge/Chrome store URLs, 32-bit view, own request creation/upgrade, pre-existing request preservation and different-source rejection; no force-install policy added |
| MSI 0.1.1 automatic browser extension install/upgrade | NOT RUN | Browser confirmation and new request behavior need a target-machine check; existing signing/cancellation/card-removal results remain accepted |

The initial clean-Windows private-DLL signing milestone is **met**: the module
loaded, a token was enumerated, Web eID selected the Belgian PKCS#11 route,
retrieved a certificate and returned independently verified signatures. Formal
Gate A's practical clean-Windows/card-operation checks are accepted as passed
for the tested package, including user-reported cancellation and card removal.
Exact selected runtime/source correspondence and distributable dependency
inventory remain release-engineering work, not additional manual PoC tests.
Gate B
(actual KYC assurance) is **not passed**. The mathematical signature checker tests
neither PDF trust nor CA trust/revocation. These backend assurance items are
owned by the KYC project; existing KYC tests/configuration evidence may supply
them. They do not require new native-app validators. Windows 10, ARM64, Linux
and macOS have no support claim.

Additional bridge coverage, outside the completed manual PoC: unsupported card,
wrong or blocked PIN, two simultaneous readers/cards, unsupported browser and
multiple card generations. Missing/private-DLL loader failures already have
automated coverage. No further manual PoC tests are requested at this stage.
KYC-owned acceptance cases: expired/revoked cert,
changed PDF/signature/digest, substituted certificate/finalization reference,
replay/cross-account submission and client-provided wrong name.
Any future retry-exhaustion testing would require a disposable test card with
human supervision; it is not part of the current tester request.

Both Windows CI workflows passed remotely. The application pins the published
library patch so a fresh checkout can run the tests. The private-DLL test archive
contains the MSVC runtime; it is a controlled PoC, not a redistributable release.
