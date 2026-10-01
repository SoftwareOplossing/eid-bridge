# Current KYC contract: source snapshot

Inspected the clean local Let's Peppol checkout at
`11683ef52bb55fc4b3f6fc7853eca2ccb5a3454d`. Paths below are relative to that
repository. This records implemented behavior, not verified production settings
or a successful transaction. No private keys, databases or personal records were read.

1. `app/ui/src/registration/email-confirmation.ts` calls
   `getSigningCertificate({lang: 'en'})` when the user confirms a director.
   It submits the certificate, supported algorithms, company and director to
   `prepareSign`. `add-ownership.ts` uses the same signing pattern.
2. `kyc/.../service/SigningService.java:prepareSigning` fills and flattens the PDF
   contract, reserves its signature field with iText and obtains a SHA-256 digest
   through `PreSignatureContainer`. The server stores the prepared PDF and digest.
3. The browser calls `webeid.sign(certificate, hashToSign, 'SHA-256')`; PIN entry is
   native. No `authenticate` call is part of the inspected signing flow.
4. The browser returns certificate, signature, algorithm, digest, finalization
   reference, company, director and email. `finalizeSign` checks certificate
   validity, verifies the raw signature with `SignatureUtil`, and consumes the
   server-stored expected digest before constructing the CMS/PDF signature.
5. `IdentityVerificationService.recordDirectorSignature` records evidence and
   compares certificate given name/surname with the selected director. A mismatch
   sends the flow to manual review; matching directors can receive ownership and
   company registration, subject to existing account/suspension conditions.

Required fields observed in source:

| Field/evidence | Current use |
|---|---|
| Signing certificate GIVENNAME + SURNAME | `SigningService.isAllowedToSign` -> `NameMatchUtil.matches` |
| CN/full name | Account naming and identity evidence |
| Certificate subject SERIALNUMBER | Included in PDF signature appearance; potentially national-registry-bearing. Do not confuse it with certificate serial number |
| Certificate serial number | Recorded encrypted in identity evidence |
| Certificate and signature | Recorded encrypted; final signed contract stored |
| Date of birth / raw card identity file | No requirement found in this path |
| Authentication certificate | Not requested by this path |
| Private-key control | Checked by raw signature verification |
| Exact prepared digest | Stored server-side and compared during finalization |

Name matching normalizes case/diacritics/whitespace. It requires every surname
token of at least two characters as a whole word in the director name and at
least one given-name token of at least two characters. Do not replace this with
new client identity data or expand collection for this bridge.

Items preventing a KYC assurance claim:

- `validateCertificateChain` skips chain validation when the truststore setting is
  blank. `application.properties` defaults the truststore to empty and revocation
  to false. A configured store does use PKIX path building with self-signed roots
  as trust anchors and intermediate certificates as path-building inputs. Actual
  staging/production configuration must be confirmed without sharing passwords.
- Key usage accepts digitalSignature **or** nonRepudiation when present; no strict
  signing policy/EKU requirement was found there. Review against the real contract.
- `PrepareSigningRequest.sha256()` deterministically hashes certificate + company
  + director. The in-memory `preparedHashes` map records only the digest under that
  reference, not a fresh session nonce/account binding. Removal provides a
  single-use check within a process, but does not establish cross-account binding,
  concurrent-session behavior, or distributed/restart-safe replay protection.
- `createFinalContract` assembles the PDF from its stored file. No independent
  final-PDF verification pass was found in this method; exact-document and
  substituted-finalization-reference tests remain necessary.
- Existing backend logs include identity fields. New PoC tools omit them, but
  sharing backend logs requires redaction.

Reader/card/PIN errors are surfaced by Web eID and frontend error handling;
per-scenario behavior is not yet verified. Expired/untrusted certificate and
replay branches exist in backend source, but no hardware/staging result has been
captured. The complete success criterion requires trusted signer identity,
correct document/signature, account/session binding, name-match outcome and
accepted backend finalization—not merely a signature that verifies mathematically.
