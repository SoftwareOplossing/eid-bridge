# Release gates and sequence

There is currently no release candidate. The portable package passed the user's
clean-Windows signing/browser/PDF path, and cancellation/card removal were
reported tested. No additional manual PoC test is requested now. Remaining work
is release engineering and KYC-owned acceptance evidence.
Do not run the upstream installer target as a Let's Peppol distribution.

1. Publish the isolated library change, then pin its reachable SHA in this app.
2. Build/test unchanged baseline using supported MSVC/Qt/vcpkg prerequisites.
3. Select the distributable middleware binary and matching source; record versions,
   notices, hashes and packaged dependency inventory. Reuse the successful
   clean-machine/card evidence for the tested portable package (practical Gate A).
4. Reuse the successful browser KYC and final-PDF result for bridge integration.
   Certificate trust/session binding and backend tamper/replay assurance belong
   to KYC; existing KYC tests and deployment evidence can supply Gate B without
   native validator changes or repeated card tests.
5. Only then choose protected installation location, verify ACLs/reparse behavior,
   native-host identity/coexistence and extension distribution. Design installer,
   upgrade/uninstall and recovery together.
6. Produce reviewed notices, SBOM, signed application/installer, authenticated
   updates, dependency scanning and documented rollback. Re-run hardware/browser
   and clean-machine tests before claiming support.

For each candidate archive exact app/library/extension/JS/middleware commits,
toolchain and dependency versions, unsigned/signed binary hashes, source and
notices, test evidence, and reviewer decisions. Keep raw identity/PIN data out of
artifacts. Middleware security updates must be independently buildable/testable
without rewriting the bridge.
