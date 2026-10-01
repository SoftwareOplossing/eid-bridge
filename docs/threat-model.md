# Initial threat model

Assets: PIN/private key, certificate identity, intended KYC PDF, signature,
account/session binding and trusted native/middleware distribution.
Boundaries: website -> JS -> extension -> native protocol -> PKCS#11 -> PC/SC ->
card, and browser -> authoritative KYC backend.

| Threat | Current control / remaining requirement |
|---|---|
| Top-level DLL substitution/search | Builder supplies one absolute path; no fallback. Production directory/parent ACLs, reparse points and binary provenance need release validation |
| Dependency hijacking | Private loader excludes CWD/PATH; tested with a dependent mock DLL. Loaded-module reuse and middleware's later dynamic loads require tracing |
| Missing/corrupt module | Fail with upstream load error; no opportunistic system fallback. Repair/reinstall UX remains future work |
| PIN/private-key disclosure | Keep upstream native/card behavior; probe never handles PIN; signing checker never accepts PIN as an argument |
| Identity in diagnostics | Probe emits counts/status only. Checker suppresses native output; fingerprint is still linkable and should remain private. Upstream/native/backend log review remains |
| Malicious website/origin spoofing | Existing extension/native protocol retained; no new Let's Peppol allowlist. Review origin handling and extension distribution before production |
| Document substitution/replay/cross-account signing | Backend must validate trusted identity and bind the exact prepared PDF to the current account/session. See the concrete gaps in current-kyc-flow.md |
| Invalid/expired/revoked identity | Chain configuration, policy and revocation requirements must be proven. Raw signature verification is insufficient |
| Multiple cards/readers | Upstream PKCS#11 enumeration is not tied to original reader; hardware ambiguity test required before support claims |
| Compromised/downgraded dependency | Pin source/binary hashes, review security changes, sign releases and define rollback/update policy before distribution |

This is a source/test review, not a completed security audit. No installer,
automatic updates, telemetry or additional identity collection was introduced.
