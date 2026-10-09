# Release gates and sequence

## Current release preparation

Version **1.1.0** selects the owner's requested vendor-signed DLL 5.2.0.6426
from official-hosted test QuickInstaller 5.2.0.6447. It packages the complete
revision 6426 source ZIP with a generated version header, rebuild/
replacement instructions and incorporated source notices. The vendor DLL is
neither changed nor re-signed. Free Community 2022 17.14.41 is installed for
this MIT project, with an independent source build completed and component-specific
Microsoft runtime terms shown during installation.

The source mapping is now `verified` based on the owner's report of confirmation
from Thomas Charlier at Zetes identifying revision 6426, combined with the checked
public source/build inventory and independent build. The original correspondence
was not independently reviewed; the commit link identifies source rather than
publishing the private confirmation. The owner also confirmed a successful
signature using the installed 1.1.0 application on the clean Windows laptop.
The builder's `-PublicRelease` option requires these accepted evidence records
and publisher entitlement. The public MSI has no candidate suffix and retains
the exact tested application and signed middleware hashes. See `release-evidence-1.1.0.json` and
`third-party/belgian-eid/official-5.2.0-provenance.json`.

The following 1.0.x/0.1.x results are historical evidence for unchanged components.

The professional product name is **Let's Peppol eID Bridge**. Version 1.0.0
uses the same upgrade identity and installation directory as 0.1.x, with
customer instructions and licence information replacing the test wording.
The locally built `1.0.0-windows-x64-unsigned-candidate.msi` passed WiX validation,
the MSI table/condition checks and all 84 extracted payload hash checks. The
native executable and Belgian DLL match the previously tested hashes; no new
native hardware test is requested for these packaging changes.

Company signing is now supported by the installer builder. It signs the staged
application before packaging, signs the MSI last, verifies the expected publisher
and timestamp, and retains both original and signed application hashes. Five
negative signing preflight cases passed without contacting the service. Real
service signing remains untested pending company account validation. Follow
[company code signing](company-code-signing.md); no additional fork is needed.

The selected Belgian DLL now has verified official binary provenance: the
official `BeidMW_64_5.1.34.6350.msi` contains the identical 5.1.34.6213 x64 DLL.
Matching source remains unresolved. A public-history commit with revision count
6213 (`7f0ed21dba8017e5c1fa58bd13664bc087211905`) has base version **5.1.23**, not
5.1.34, so it cannot be assumed to match the selected binary. Preserve the tested
DLL while obtaining an authoritative matching source revision/build recipe.

Version 1.0.1 adds verified Qt/Mesa component notices, OpenSSL attribution,
Microsoft terms and official Belgian Toolkit agreements. It excludes the redundant
Windows 8.1 Direct3D compiler. WiX validation, MSI table/condition checks, all
98 extracted payload manifest checks and native browser startup/logging passed.
All four Toolkit agreements match the official MSI byte-for-byte; the native
application and middleware hashes remain unchanged. No installation or card/PIN
test was performed. See [licensing status](licensing.md).

The historical candidate remained private until corresponding middleware source/notices and
publisher Microsoft redistribution entitlement are established. Company signing
is optional when the publisher chooses unsigned distribution.
The builder records `public_release=false` even when a candidate is signed;
signing alone does not satisfy redistribution obligations. The website fallback
changes remain local and are not deployed by building the installer.

## Existing evidence and release sequence

An unsigned private Windows 11 x64 test MSI is built. The portable package passed
the user's clean-Windows signing/browser/PDF path, and cancellation/card removal
were reported tested. No additional manual PoC test is requested now. Installing,
upgrading and new extension-request behavior still need physical-machine confirmation.
The user reports installation and uninstallation of 0.1.0 worked on the laptop.
See [installer build and migration](windows-installer.md). Do not publish the
test MSI or use the upstream installer identity for this fork.

1. Publish the isolated library change, then pin its reachable SHA in this app.
2. Build/test unchanged baseline using supported MSVC/Qt/vcpkg prerequisites.
3. Select the distributable middleware binary and matching source; record versions,
   notices, hashes and packaged dependency inventory. Reuse the successful
   clean-machine/card evidence for the tested portable package (practical Gate A).
4. Reuse the successful browser KYC and final-PDF result for bridge integration.
   Certificate trust/session binding and backend tamper/replay assurance belong
   to KYC; existing KYC tests and deployment evidence can supply Gate B without
   native validator changes or repeated card tests.
5. Verify the test MSI's protected installation location, ACLs, conflict rejection,
   upgrade/uninstall and rollback on the target PC. The source and MSI table/
   condition checks implement these; they are not a physical installation test.
6. Produce reviewed notices, SBOM, application/installer (signed if selected), authenticated
   updates, dependency scanning and documented rollback. Re-run hardware/browser
   and clean-machine tests when release changes require them before claiming support.

For each candidate archive exact app/library/extension/JS/middleware commits,
toolchain and dependency versions, unsigned/signed binary hashes, source and
notices, test evidence, and reviewer decisions. Keep raw identity/PIN data out of
artifacts. Middleware security updates must be independently buildable/testable
without rewriting the bridge.
