# Redistribution preparation

No Belgian middleware binary is tracked or published by this checkout. The private
local MSI bundles the same signed 5.1.34.6213 DLL tested on the clean laptop,
SHA-256 `b3e5bbd5112b5ef55f4189bdf334c989abf99f27c1cfb3c2a3e784efd780cf93`.
The same DLL was extracted from the official Belgian middleware installer
`BeidMW_64_5.1.34.6350.msi`, confirming its official origin; see
`third-party/belgian-eid/SOURCE.md` and `checksums.txt`. Matching middleware source
is not established; this MSI must not be published.
The copied
`third-party/belgian-eid/LICENSE` is the upstream COPYING file from inspected
commit `cf2d593181c56de33198993278d64990292772c1`; it does not identify the source of
the already installed baseline DLL.

Web eID/libelectronic-id use MIT notices. Belgian middleware source declares
LGPL-3.0-or-later; inventory all incorporated third-party notices for the exact
selected runtime. Preserve upstream notices, including the PKCS#11 header notice.

Before redistributing: identify exact binary/build inputs and corresponding
source; provide applicable LGPL/GPL texts and copyright notices; document any
middleware modifications and build instructions; preserve dynamic separation
and the user's applicable replacement/relinking rights. Determine how component
replacement interacts with signed-package/update policy. Do not introduce a hash
lock that silently prevents required replacement of the LGPL component.

The VC++ runtime requires its own redistribution review. Qt/OpenSSL and the
application's other bundled dependencies require a complete notice inventory.
The concrete distribution must satisfy these obligations; an LGPL file alone
does not establish corresponding source, complete notices or a build recipe.

The private MSI preserves app/library MIT and Belgian LGPL notices, includes
GPL/LGPL v3 texts and Qt source links, and copies vcpkg copyright files from the
native build. Qt's incorporated third-party notice inventory and Microsoft runtime
redistribution review remain incomplete. BUILD-INFO.json explicitly records
`corresponding_middleware_source_verified=false`; runtime DLL replacement is not
blocked by an application hash check. Packaging verifies the selected input hash
to avoid accidentally changing the tested candidate.

## Product branding

The Web eID application and `libelectronic-id` source are MIT-licensed. Covered
code, UI text and artwork may be modified and redistributed while preserving
copyright and license notices; inspect any asset-specific notices as well. The
MIT licence does not require the original help link. It may be replaced with our
onboarding URL or support email, or removed; the preserved notices and upstream
attribution in About satisfy a different purpose from a customer support link. The
Belgian middleware's LGPL obligations
remain separate. Open-source copyright permission does not grant a right to
present our fork as an official Web eID or Belgian government product; replace
the upstream brand in user-facing materials and attribute Web eID in About and
license notices. The Let's Peppol logo used in the About dialog is copied from
the local MIT-licensed Let's Peppol project (`app/ui/public/logo-only.svg`),
as requested by the user for this product.
