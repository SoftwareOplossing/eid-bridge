# Upstream maintenance

The starting application commit is `9f926877aee9cbbc42af7022baa1c30f1a0057fa`
(version declaration 2.11.0). `upstream` is
<https://github.com/web-eid/web-eid-app.git>; `origin` is
<https://github.com/SoftwareOplossing/eid-bridge.git>.

The library starts at `c0cbecb577b1559380d2e6d508cdf81e1101fb99`.
Its user-created fork is <https://github.com/SoftwareOplossing/libelectronic-id.git>;
its `upstream` is <https://github.com/web-eid/libelectronic-id.git>.
The library patch is commit `0225293b40f9d7a17e4b87a6d7b3ea1f8a5b663c`
on published branch `codex/private-beid-module`; this app pins that commit.
The extension and JS library remain pinned upstream submodules, without forks.
Absolute submodule URLs prevent Git from looking for nonexistent sibling forks.

Fork-specific runtime changes belong in the library: one optional build-time
Belgian module path and restricted Windows loading for that module. The empty
setting preserves upstream behavior. Keep native message names, internal APIs,
card detection, certificate selection, signing and PIN behavior upstream-compatible.

The library patch was published before the application's submodule pointer was
updated. Keep this order for subsequent updates. Do not publish an application
commit that references a local-only library commit.

For updates:

1. Start from clean worktrees. Fetch each repository's upstream and record its SHA.
2. Review security, protocol, Belgian ATR, PKCS#11 and PIN changes before rebasing.
3. Rebase the isolated library changes onto the chosen library base and run both
   default and private-path Windows tests. Publish the library commit first.
4. Rebase the application changes onto the chosen app base. Update its library
   pointer explicitly; never use `git submodule update --remote` in a release build.
5. Run upstream tests and the hardware/clean-VM matrix. Pin and review middleware
   binaries independently; updating Web eID does not implicitly approve new DLLs.

See [inventory](docs/upstream-inventory.md) and [PoC commands](poc/README.md).
