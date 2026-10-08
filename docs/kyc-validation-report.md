# KYC validation report

Status on 2026-10-08: Edge onboarding certificate check reported working on
the clean Windows laptop after native-host registration repair. The user also
reports that contract signing works. Backend completion, downloaded final PDF
integrity and the full assurance gate remain unverified.

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
| Exact final PDF | Intended content unchanged; cryptographic signature valid | NOT RUN | Offline `check-kyc-pdf` verifies signature/whole-file coverage; intended document/account still requires backend evidence |
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
