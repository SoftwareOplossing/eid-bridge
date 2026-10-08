# Belgian eID binary provenance and source status

The selected Windows x64 DLL (file version `5.1.34.6213`) matches the x64
PKCS#11 DLL extracted from the official installer:
<https://dist.eid.belgium.be/releases/5.1.34/BeidMW_64_5.1.34.6350.msi>.
Both hashes are recorded in `checksums.txt`. The installer and extracted DLL
have valid ZETES SA Authenticode signatures. The DLL is unchanged; its original
signature is retained. No official middleware installer is run by this bridge.

This confirms the binary's official origin, **not its corresponding source**.
The public repository is <https://github.com/Fedict/eid-mw>. At the release audit,
no matching v5.1.34 tag was available. The Windows revision is generated using
`git rev-list --count HEAD`; a matching version number alone is insufficient to
claim corresponding source. Public redistribution remains pending exact source
identification, its incorporated notices and build/replacement instructions.

Investigation snapshot:
<https://github.com/Fedict/eid-mw/tree/cf2d593181c56de33198993278d64990292772c1>.
`LICENSE` is copied verbatim from its `COPYING` file.

No DLL is tracked in this repository. This snapshot is not asserted to be corresponding source
for a selected release binary. Before bundling, record official binary URL/build
recipe, exact source tag/commit, toolchain, architecture, SHA-256, modifications,
all notices and the source/replacement mechanism. See `docs/licensing.md`.
