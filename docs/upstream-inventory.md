# Upstream inventory

Inspected 2026-09-27. Source findings are not physical-card test results.

| Repository | Inspected commit | Role |
|---|---|---|
| [web-eid-app](https://github.com/web-eid/web-eid-app/tree/9f926877aee9cbbc42af7022baa1c30f1a0057fa) | `9f926877aee9cbbc42af7022baa1c30f1a0057fa` | App fork base; also upstream HEAD at inspection |
| [libelectronic-id](https://github.com/web-eid/libelectronic-id/tree/c0cbecb577b1559380d2e6d508cdf81e1101fb99) | `c0cbecb577b1559380d2e6d508cdf81e1101fb99` | App's pinned library; retained as patch base |
| [web-eid-webextension](https://github.com/web-eid/web-eid-webextension/tree/e949ac369bdbb41e45af0b7b3eca21d239676509) | `e949ac369bdbb41e45af0b7b3eca21d239676509` | Unchanged submodule; native host `eu.webeid` in `src/config.ts` |
| [web-eid.js](https://github.com/web-eid/web-eid.js/tree/652f2bdbc173c188f859408e1beed6983c1af9c4) | `652f2bdbc173c188f859408e1beed6983c1af9c4` | Extension's unchanged nested submodule |
| [architecture](https://github.com/web-eid/web-eid-system-architecture-doc/tree/acf02d95466d2f4b95c948c47415818b3b0e071d) | `acf02d95466d2f4b95c948c47415818b3b0e071d` | Authentication/signing protocol and trust boundaries |
| [eid-mw](https://github.com/Fedict/eid-mw/tree/cf2d593181c56de33198993278d64990292772c1) | `cf2d593181c56de33198993278d64990292772c1` | Middleware source investigation only; not the source identification of a shipped binary |
| Local Let's Peppol application | `11683ef52bb55fc4b3f6fc7853eca2ccb5a3454d` | Clean checkout at `C:/LetsPeppol/letspeppol`; KYC source inspected read-only |

At initial inspection, upstream/fork HEAD was `9fa5a6954bae10d875c30621c69be838f525f493`.
Its only change after the pinned library base was a CodeQL dependency update.
The application now deliberately pins the SoftwareOplossing library patch at
`2f1cffc9b99919c8172405ca265f28a7cb8caee7` (`codex/private-beid-module`), adding
the private and executable-directory Belgian module options plus loader tests.

Library source locations, relative to `lib/libelectronic-id`:

| Concern | Evidence |
|---|---|
| Detection | `src/electronic-id.cpp`: exact Belgian Applet 1.8 ATR and masked BelEID v1.7 ATR route to `Pkcs11ElectronicID<BelEID>`; hardware generations still need validation |
| Discovery | `src/electronic-ids/pkcs11/Pkcs11ElectronicID.cpp`: Windows System32 `beidpkcs11.dll`; macOS `/Library/Belgium Identity Card/Pkcs11/beid-pkcs11.bundle/Contents/MacOS/libbeidpkcs11.dylib`; Linux `/usr/lib/x86_64-linux-gnu/libbeidpkcs11.so.0` |
| Initialization | `PKCS11CardManager.hpp`: load DLL, get function list, initialize; shared manager per module path |
| Selection | Enumerates slots with tokens, opens sessions and reads certificate objects; classifies signing by nonRepudiation key usage in `src/electronic-ids/x509.hpp` |
| Multiple cards | PKCS#11 constructor ignores the original PC/SC reader; iterates all module tokens and retains the last certificate of each type. This is a hardware test/review item, not proven deterministic card selection |
| Private key | Matches CKA_ID from selected certificate, requires exactly one matching private key |
| Signing | CKM_RSA_PKCS with DigestInfo, or CKM_ECDSA with raw hash; supported algorithms derived from certificate and checked after signing |
| PIN | Belgian module sets external PIN dialog flag; no browser PIN handling. Windows middleware PIN UI/pinpad behavior requires hardware checks |
| Errors | Maps cancellation, incorrect/blocked PIN, token removal and other PKCS#11 statuses to existing exceptions |
| Other Windows route | `src/availableSupportedCards.cpp`: CryptoAPI fallback if no tier 1/2 cards were found. Validate that test cards take the intended Belgian PKCS#11 route |

Build dependencies: CMake >=3.22, Qt >=6.2 (upstream build script uses 6.11.2),
OpenSSL >=3.0 and GTest. The library's vcpkg baseline is
`99e82d9c9f0b281ec11fba48cc8434574a2b6e66`, with OpenSSL registry baseline
`6daff78a7188881762bb2c6aef721b3c1f35edb7`.

Local results: standalone loader/probe compiled using MinGW GCC 15.2.0 and CMake
3.31.6. Full native configuration stopped at missing Qt development files. The
upstream Windows build is MSVC-based; no MinGW port of the full app is proposed.
Stock-app hardware baseline T1 and the clean-laptop PoC/browser signing checks
subsequently passed; see test-matrix.md. Full native app compilation/tests passed
in Windows CI using MSVC/Qt rather than the local MinGW toolchain.
