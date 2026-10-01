# Redistribution preparation

No Belgian middleware binary is redistributed by this checkout. The copied
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
Legal review of the concrete distribution/replacement mechanism remains a release
gate; an LGPL file alone is not completion of redistribution obligations.
