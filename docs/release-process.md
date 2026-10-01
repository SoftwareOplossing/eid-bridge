# Release gates and sequence

There is currently no release candidate. This change prepares source and tests.
Do not run the upstream installer target as a Let's Peppol distribution.

1. Publish the isolated library change, then pin its reachable SHA in this app.
2. Build/test unchanged baseline using supported MSVC/Qt/vcpkg prerequisites.
3. Select middleware binary and matching source; record versions, licenses and
   hashes, and obtain clean-machine dependency/card evidence (Gate A).
4. Validate the existing KYC contract and resolve trust/session-binding questions;
   pass complete PDF, identity, tamper and replay tests (Gate B).
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
