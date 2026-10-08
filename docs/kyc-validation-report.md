# KYC validation report

Status on 2026-10-08: Edge onboarding certificate check reported working on
the clean Windows laptop after native-host registration repair. The user also
reports that contract signing works and supplied a downloaded PDF check that
failed strict parsing (`PdfStrictReadError`). A PDFBox/iText interoperability
restriction was reproduced with synthetic data and handled in the offline
checker. The earlier local KYC workaround was removed; the user's exact PDF
and the full assurance gate remain unverified.

## Next controlled transaction

Use the same laptop, portable app, private Belgian DLL and official Edge
extension. Keep the repaired current-user native-host registration in place.
Select a staging/test company account before starting the transaction. The
current live URL is `https://be.letspeppol.org/onboarding`; its installation
check is complete. A real contract signing at that URL needs a company
registration the tester intends and is authorized to complete. The test route
has not yet been selected.

1. Follow the existing registration/director-confirmation flow. Verify the
   intended company, director and contract shown by the website.
2. Let the existing backend prepare its usual KYC PDF and signing digest.
3. Approve that intended signature and enter the PIN in the native UI.
4. Record the site's success/error outcome and whether the final PDF downloads.
   A downloaded PDF or success screen alone does not establish trusted KYC.
5. Verify the final PDF signature, intended content and signer against the
   backend's prepared transaction. Confirm certificate-chain enforcement and
   the configured revocation policy, and check director/account binding.
6. Run tamper/replay cases in the controlled test environment. Record rejected
   responses and ensure no ownership/registration is granted for failures.

Keep the original PDF, signing certificate, certificate fingerprint and
identifying records in private test evidence. Commit only non-identifying
status and reproducible test descriptions here. Never collect or share the PIN.

## Results

| Test | Expected | Result | Evidence |
|---|---|---|---|
| Edge onboarding installation check | Certificate and SHA-256 support retrieved | PASS, user-reported | Confirmed working after helper repair on 2026-10-08 |
| Native KYC contract signing | Signature returned through the existing browser flow | PASS, user-reported | User reported signing works on 2026-10-08; no identifying data collected |
| Completed KYC transaction | Correct backend identity/account outcome and final PDF | PENDING CONFIRMATION | Site completion and PDF download outcome requested |
| Exact final PDF | Intended content unchanged; cryptographic signature valid | AWAITING UPDATED CHECKER RESULT | Original strict checker raised `PdfStrictReadError`; recheck the same downloaded file with the compatibility checker. Intended document/account still requires backend evidence |
| Trusted signing certificate | Chain, validity and required policy pass | NOT RUN | Confirm deployed truststore and revocation policy |
| Altered PDF/digest/signature | Rejected; no registration granted | NOT RUN | Controlled backend test |
| Substituted certificate | Rejected | NOT RUN | Controlled backend test |
| Untrusted/expired certificate | Rejected | NOT RUN | Controlled backend test |
| Replayed/cross-account transaction | Rejected | NOT RUN | Fresh reference and account binding must be proven |
| Wrong director/client identity | No automatic ownership granted | NOT RUN | Preserve existing manual-review contract |
| Cancelled native signature | No completed transaction; retry can recover | NOT RUN | Human cancels; no deliberate wrong-PIN attempts |

Backend source findings and remaining assurance issues are recorded in
[current-kyc-flow.md](current-kyc-flow.md). This report does not assert that
the production configuration uses the source defaults. Gate B remains open;
production installer work follows successful validation. Formal Gate A also
still requires clean-laptop module/dependency evidence and negative testing.

## PDF interoperability reproduction and checker compatibility

The KYC backend fills/flattens its template with PDFBox 3.0.2, saves it with
default compression, then uses iText 9.3.0 append mode to prepare and finalize
the signature. A local reproduction used that public template, the backend's
signing containers/CMS wrapper, and a generated synthetic RSA key/certificate.
It reproduced `PdfStrictReadError`: `XRef stream objects must not be clobbered
in strict mode.` The initial PDF parsed strictly; the prepared and final
revisions failed. Compatibility parsing of the synthetic final file verified
the signature and entire-file coverage. No private user contract was inspected;
the same exception class alone does not confirm their exact parser failure.

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
synthetic PDFBox/iText contract also passes the updated checker. The user can
recheck their existing downloaded PDF with the updated executable; no website
deployment or fresh signature is required for this integrity check.
