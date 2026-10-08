# KYC validation report

Status on 2026-10-08: Edge onboarding certificate check reported working on
the clean Windows laptop after native-host registration repair. The user also
reports successful KYC/registration for the intended company and director.
The downloaded contract passed the updated offline checker: one signature,
intact signed bytes, valid cryptographic signature and whole-file coverage.
The reported xref compatibility mode confirms the original strict parser
restriction. The earlier local KYC workaround was removed. Certificate trust,
revocation, independent document/account binding and the full assurance gate
remain unverified.

## Responsibility boundary

Certificate trust, revocation policy, intended-document/account binding and
backend tamper/replay rejection belong to the KYC project. They are not new
features to implement in the Web eID fork. Existing KYC tests and deployment
configuration evidence can satisfy these parts of the end-to-end acceptance
gate; duplicating the validators in the native app is unnecessary.

The bridge's integration responsibility is to preserve the existing certificate,
digest and signature protocol while replacing installed middleware with the
private runtime. The successful browser transaction and final-PDF verification
provide evidence for that path. The user also reports cancellation and card
removal tested; clean-install success is accepted as practical runtime dependency
evidence for this PoC. Remaining bridge work concerns selecting the distributable
runtime/source, documenting packaged files and creating release installation.
The plan's broader Gate B remains a cross-project acceptance
requirement, rather than a mandate to change KYC code in this repository.

## KYC-owned acceptance evidence

The user has completed the success path using the same laptop, portable app,
private Belgian DLL and official Edge extension at
`https://be.letspeppol.org/onboarding`. Keep that result as reported evidence.
Use a controlled staging/test environment for remaining tamper/replay cases;
that test route has not yet been selected.

1. Confirm deployed certificate-chain enforcement, validity/policy checks and
   the configured revocation policy using non-identifying configuration evidence.
2. Compare the intended content and signer in the final PDF against the backend's
   prepared transaction, and independently verify director/account binding.
3. Run tamper/replay cases in the controlled test environment. Record rejected
   responses and ensure no ownership/registration is granted for failures.

Keep the original PDF, signing certificate, certificate fingerprint and
identifying records in private test evidence. Commit only non-identifying
status and reproducible test descriptions here. Never collect or share the PIN.

## Results

| Test | Expected | Result | Evidence |
|---|---|---|---|
| Edge onboarding installation check | Certificate and SHA-256 support retrieved | PASS, user-reported | Confirmed working after helper repair on 2026-10-08 |
| Native KYC contract signing | Signature returned through the existing browser flow | PASS, user-reported | User reported signing works on 2026-10-08; no identifying data collected |
| Completed KYC transaction | Intended company/director outcome and final PDF | PASS, user-reported | User confirmed successful KYC/registration for the intended company and director on 2026-10-08; this does not independently establish backend trust policy or account binding |
| Downloaded final PDF integrity | Signed bytes intact; cryptographic signature valid; whole-file coverage | PASS, user-reported | Updated checker reported one signature with all three checks true and `integrity_check_passed=true`; `pdf_parse_mode=xref_compatibility`, `parser_issue=xref_stream_object_reused` |
| Intended document/account binding | Prepared contract, intended signer and account independently matched | NOT RUN | Successful site outcome and PDF integrity do not independently prove backend transaction/account binding |
| Trusted signing certificate | Chain, validity and required policy pass | NOT RUN | Confirm deployed truststore and revocation policy |
| Altered PDF/digest/signature | Rejected; no registration granted | NOT RUN | Controlled backend test |
| Substituted certificate | Rejected | NOT RUN | Controlled backend test |
| Untrusted/expired certificate | Rejected | NOT RUN | Controlled backend test |
| Replayed/cross-account transaction | Rejected | NOT RUN | Fresh reference and account binding must be proven |
| Wrong director/client identity | No automatic ownership granted | NOT RUN | Preserve existing manual-review contract |
| Cancelled native signature | Operation aborts cleanly | PASS, user-reported | User reports cancellation already tested on 2026-10-08; detailed timing/dialog evidence not collected |
| Card removal/recovery | Operation fails cleanly and reinsertion permits recovery | PASS, user-reported | User reports card removal already tested on 2026-10-08; exact removal timings not collected |

Backend source findings and remaining assurance issues are recorded in
[current-kyc-flow.md](current-kyc-flow.md). This report does not assert that
the production configuration uses the source defaults. Gate B remains open
for cross-project acceptance evidence; existing KYC validation can supply it.
This does not expand the bridge implementation to own those validators.
Gate A's practical clean-machine/card-operation checks are accepted as passed
for the tested package. Further manual PoC repetition is unnecessary; exact
runtime/source inventory and installer verification remain engineering work.

## PDF interoperability reproduction and checker compatibility

The KYC backend fills/flattens its template with PDFBox 3.0.2, saves it with
default compression, then uses iText 9.3.0 append mode to prepare and finalize
the signature. A local reproduction used that public template, the backend's
signing containers/CMS wrapper, and a generated synthetic RSA key/certificate.
It reproduced `PdfStrictReadError`: `XRef stream objects must not be clobbered
in strict mode.` The initial PDF parsed strictly; the prepared and final
revisions failed. Compatibility parsing of the synthetic final file verified
the signature and entire-file coverage. No private user contract was inspected;
the user's subsequent compatibility report confirms this same parser restriction
for their downloaded file, with all three signature integrity checks passing.

The installed pyHanko 0.37.0 source explicitly documents that its xref stream
reuse restriction is stricter than the PDF specification. Its motivation is
encryption/cache semantics. This is a reader compatibility restriction, not
evidence that all existing signed contracts are malformed or have bad signatures.
An initial local workaround used a classic xref save in KYC; that source change
and its added Java test have now been removed. No website changes were deployed
or remain necessary for this checker compatibility issue.

The offline checker tries strict parsing first. Only the exact known xref reuse
error triggers a rewind of the same file and a compatibility parse. Encrypted
files are rejected by this fallback. Other strict errors remain failures. It
validates the original bytes without rewriting the PDF and still requires one
signature, intact signed bytes, a cryptographically valid CMS signature and
whole-file coverage. Its JSON reports `pdf_parse_mode=xref_compatibility` and
`parser_issue=xref_stream_object_reused` when the fallback was used; normal
strictly parsed files report `pdf_parse_mode=strict`. Trust, revocation and
expected document/account remain explicitly unverified.

All 26 Python tests passed, including compact synthetic compressed xref-reuse
PDFs: valid signatures pass; unsigned documents, changed signed content, altered
CMS signatures and later incremental updates fail. Other strict errors do not
trigger fallback, and encrypted compatibility input is rejected. The original
synthetic PDFBox/iText contract also passes the updated checker. The user then
rechecked the same downloaded contract and reported a pass. No website deployment
or fresh signature was required. The explicit false trust, revocation and
expected-document/account fields mean those checks are outside this tool's
scope, not that the certificate or account was found invalid.
