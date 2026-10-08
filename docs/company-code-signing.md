# Company code signing

Recommended: Microsoft Artifact Signing, Basic tier, **Public Trust** profile,
organization validation, West Europe. The service supports EU organizations and
keeps the signing key in its managed service. Use the actual legal company name
as publisher; the application can keep the Let's Peppol product brand.

## One-time company setup

An authorized company representative completes these steps in the
[Azure portal](https://portal.azure.com), using a company Microsoft Entra tenant
and a paid Azure subscription (pay-as-you-go or enterprise agreement; the service
does not accept free, trial or sponsored subscriptions):

1. Register the `Microsoft.CodeSigning` resource provider in the subscription.
2. Create an Artifact Signing account in West Europe, Basic tier. Check the
   displayed subscription price before creating this paid resource.
3. Under Identity validations, create **Organization / Public** validation.
   Supply the registered legal name, business identifier, address, company
   website, two company-domain email addresses and representative's details.
   Complete Microsoft's company and representative verification requests in
   the portal. Keep identity documents and credentials outside this repository.
4. Once validation is Completed, create a **Public Trust** certificate profile
   using that validated identity. Do not select Public Trust Test or Private Trust.
5. Assign the signing operator the **Artifact Signing Certificate Profile Signer**
   role at the profile scope. Identity validation uses the separate Identity
   Verifier role; subscription ownership alone does not grant signing rights.

Send only the account name, profile name, region/endpoint and the exact displayed
publisher name when ready. No certificate private key needs to be exported.

Official references:
[account and company verification](https://learn.microsoft.com/en-us/azure/artifact-signing/quickstart),
[roles](https://learn.microsoft.com/en-us/azure/artifact-signing/tutorial-assign-roles),
[pricing](https://azure.microsoft.com/en-us/pricing/details/artifact-signing/).

## Signing machine

Install Microsoft's x64 Artifact Signing Client Tools and Azure CLI on the
signing machine. The client installer supplies SignTool, its plugin, .NET 8 and
VC runtime prerequisites:

```powershell
winget install -e --id Microsoft.Azure.ArtifactSigningClientTools
```

Follow [Microsoft's SignTool integration instructions](https://learn.microsoft.com/en-us/azure/artifact-signing/how-to-signing-integrations)
for actual SignTool and x64 `Azure.CodeSigning.Dlib.dll` locations. Authenticate
with `az login` as the assigned signing operator. Copy
`install/artifact-signing.example.json` to `build/signing/metadata.json` and
replace the account/profile placeholders. The endpoint must match the region:
West Europe uses `https://weu.codesigning.azure.net`.

## Build and sign a candidate

Use PowerShell 7 and the existing verified native runtime. Supply these additional
parameters to `poc/scripts/build-installer.ps1`:

```powershell
-SignTool '<actual x64 signtool.exe path>' `
-SigningDlib '<actual x64 Azure.CodeSigning.Dlib.dll path>' `
-SigningMetadata build/signing/metadata.json `
-ExpectedPublisher '<exact validated company publisher name>'
```

The builder first verifies the original CI executable hash, copies the runtime
to a private staging directory, signs **only our application**, then hashes and
packages that signed file. Original `NATIVE-BUILD.json` provenance stays intact;
`BUILD-INFO.json` records both the unsigned and packaged application hashes.
It signs the MSI last and writes its final hash in the candidate build report.
Third-party DLLs retain their original signatures. Nothing is uploaded or
published by this script. Without the signing parameters it produces an explicitly
named `unsigned-candidate.msi`.

`sign-artifact.ps1` requires SHA-256, Microsoft's timestamp service, SignTool
verification and a valid timestamped Authenticode signature matching the expected
company. Timestamping is required because Artifact Signing certificates are
short-lived. This workflow has not been exercised against a company account yet.
Unsigned builds and signing preflight are tested locally.

A signed candidate is not automatically a public release: corresponding Belgian
middleware source and the full dependency notice inventory are still pending.
See `docs/release-process.md`. Signing does not guarantee immediate SmartScreen
reputation; see [Microsoft's FAQ](https://learn.microsoft.com/en-us/azure/artifact-signing/faq).
