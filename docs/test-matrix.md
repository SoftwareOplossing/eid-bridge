# Validation status

Initial run: Windows development host, 2026-09-27. CMake 3.31.6 / MinGW GCC 15.2.0;
Python 3.13 / cryptography 50.0.1. Hardware baseline added 2026-10-01 with an
inserted Belgian eID. No PIN or identifying certificate data is recorded here.

| Check | Result | Evidence / next action |
|---|---|---|
| Standalone native probe compilation | PASS | `cmake --build build/poc-native` |
| Native automated suite | PASS, 8 CTest cases | Mock enumeration, required-token failure, missing export, relative path rejection; default/private resolution, sibling dependency success, CWD/PATH dependency exclusion, eleven configuration inputs (valid configurations also compiled) |
| Independent signature checker | PASS, 8 unittest cases | Synthetic RSA/ECC, altered digest/signature, substituted cert, wrong algorithm, malformed ECC, native errors and timeout |
| Installed system middleware load/init | PASS, baseline only | Signed version 5.1.34.6213; PKCS#11 init/enumeration returned CKR_OK with one token after card insertion |
| Full native build | PASS in Windows CI | Portable Windows x64 PoC workflow built and ran tests; clean-PC runtime validation remains pending |
| T1 stock app + system middleware + card | PASS, preliminary | Installed Web eID 2.8.0 retrieved the signing certificate and signed the fixed SHA-256 digest; independent RSA PKCS#1 v1.5 verification passed after private PIN entry. Repeat on the plan's pinned version before final gate. |
| T2 current staging KYC | NOT RUN | Trace existing backend acceptance and redacted evidence |
| POC-1 private DLL on clean Windows | NOT RUN | Requires clean snapshot and approved binary/dependencies |
| POC-2 Belgian token | NOT RUN | Probe's token count is zero on current host; enumeration alone does not establish Belgian identity |
| POC-3 signing certificate | NOT RUN | Real Web eID command and intended certificate/card |
| POC-4 PIN signature and verification | NOT RUN | Correct PIN success; wrong PIN rejected; do not automate PIN attempts |
| POC-5 removal/reinsertion | NOT RUN | Test before PIN/during sign and recovery |
| KYC exact PDF/identity/account binding | NOT RUN | Current backend source has open assurance items |
| Chrome/Edge/Firefox | NOT RUN | Browser KYC tests after native baseline |

Gate A (clean Windows load/certificate/signature) and Gate B (actual KYC assurance)
are **not passed**. The mathematical signature checker tests neither PDF trust
nor CA trust/revocation. Windows 10, ARM64, Linux and macOS have no support claim.

Remaining negative/manual matrix: absent reader/card, unsupported card, wrong or
blocked PIN, cancellation, removal, expired/revoked cert, two readers/cards, missing
or corrupt private DLL despite installed middleware, changed PDF/signature/digest,
substituted certificate/finalization reference, replay/cross-account submission,
client-provided wrong name, unsupported browser and multiple card generations.
Use a disposable test card for retry-exhaustion tests with human supervision.

Both Windows CI workflows have passed remotely. The application pins the
published library patch so a fresh checkout can run the tests. The portable
archive is being revised to include the MSVC runtime before clean-PC use.
