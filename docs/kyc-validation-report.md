# KYC validation report

Status on 2026-10-08: Edge onboarding certificate check reported working on
the clean Windows laptop after native-host registration repair. The user also
reports that contract signing works and supplied a downloaded PDF check that
failed strict parsing (`PdfStrictReadError`). A PDFBox/iText interoperability
issue was reproduced with synthetic data and fixed locally in the KYC service;
the user's exact PDF and the full assurance gate remain unverified.

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
| Exact final PDF | Intended content unchanged; cryptographic signature valid | BLOCKED BY STRICT PARSING, user-reported | User's downloaded file raises `PdfStrictReadError`; this does not establish an invalid signature. Recheck a newly signed contract after the local backend fix is deployed. Intended document/account still requires backend evidence |
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

## PDF interoperability reproduction and local fix

The KYC backend fills/flattens its template with PDFBox 3.0.2, saves it with
default compression, then uses iText 9.3.0 append mode to prepare and finalize
the signature. A local reproduction used that public template, the backend's
signing containers/CMS wrapper, and a generated synthetic RSA key/certificate.
It reproduced `PdfStrictReadError`: `XRef stream objects must not be clobbered
in strict mode.` The initial PDF parsed strictly; the prepared and final
revisions failed. Compatibility parsing of the synthetic final file verified
the signature and entire-file coverage. No private user contract was inspected;
the same exception class alone does not confirm their exact parser failure.

The minimal backend change saves the initial contract with
`CompressParameters.NO_COMPRESSION`, giving iText a classic cross-reference
table to append to. The resulting synthetic signed file passed the independent
strict checker, including signed-byte integrity, cryptographic validity and
whole-file coverage. Neither the native bridge nor the extension needed changes.
The reviewable change and Java regression test are retained in
[kyc-pdf-classic-xref.patch](../poc/patches/kyc-pdf-classic-xref.patch) and applied
locally to `C:/LetsPeppol/letspeppol/kyc`; nothing was deployed.

The Java regression calls the actual `generateFilledContract`, checks the xref
format, prepares the normal signature appearance, and completes a synthetic
Web eID-style RSA signature through the backend CMS containers. iText confirms
one cryptographically valid signature covering the whole document. Production
compilation and the isolated regression passed. The ordinary Gradle test command
was blocked by a pre-existing `AccountUserDetailsTest.java:50` Jackson module
type mismatch, so a local init script restricted test compilation to this new
regression; the full Java test suite has not passed.

The offline checker's strict parsing is retained. It now reports the static
`parser_issue=xref_stream_object_reused` for the known error, or
`strict_pdf_structure_rejected` for other strict errors, without printing private
exception payloads. All 19 Python signature/diagnostic tests passed. Rechecking
the original PDF with this diagnostic can confirm whether its failure matches.
Do not rewrite an already signed PDF to change its encoding: rebuild/redeploy
the KYC service and sign a newly generated contract before checking again.
