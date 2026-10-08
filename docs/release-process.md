# Release gates and sequence

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
6. Produce reviewed notices, SBOM, signed application/installer, authenticated
   updates, dependency scanning and documented rollback. Re-run hardware/browser
   and clean-machine tests when release changes require them before claiming support.

For each candidate archive exact app/library/extension/JS/middleware commits,
toolchain and dependency versions, unsigned/signed binary hashes, source and
notices, test evidence, and reviewer decisions. Keep raw identity/PIN data out of
artifacts. Middleware security updates must be independently buildable/testable
without rewriting the bridge.
