# Ready-to-send upstream source request

Historical draft for the previous 5.1.34 private candidate. It was not posted.
The selected DLL is now 5.2.0.6426 from the 5.2.0.6447 test wrapper; do not send
this old request as though it concerns the current package.

Destination: <https://github.com/Fedict/eid-mw/issues>

Title: Corresponding source and build instructions for official Windows 5.1.34 PKCS#11 DLL

We are preparing an open-source Windows application that dynamically loads the
unmodified Belgian eID PKCS#11 module. Before redistributing it, we want to make
the exact corresponding source, build instructions and notices available.

Official binary package:
<https://dist.eid.belgium.be/releases/5.1.34/BeidMW_64_5.1.34.6350.msi>

- MSI SHA-256: `d67b88fd920aea63a3df6abaf05163508b130011c8e4f1cfa7fcbb8e4779c5f1`
- Extracted x64 `beidpkcs11.dll` file version: `5.1.34.6213`
- DLL SHA-256: `b3e5bbd5112b5ef55f4189bdf334c989abf99f27c1cfb3c2a3e784efd780cf93`
- Original ZETES SA Authenticode signature is retained; no middleware modification.

Could you identify the exact source commit/tag or provide the corresponding
source archive and Windows x64 build instructions, including incorporated
dependencies and applicable notices, for this DLL?

We could not find a public `v5.1.34` tag. The public-history commit with revision
count 6213 (`7f0ed21dba8017e5c1fa58bd13664bc087211905`) has base version 5.1.23,
so we have not assumed that it corresponds to this 5.1.34 binary. The MSI's
release version and DLL's file version also differ. An authoritative mapping
would help us preserve the tested module while providing the correct source.

We already retain the LGPL text and the official MSI's language-specific
Toolkit agreements. Please also confirm whether any additional component notices
must accompany redistribution of this PKCS#11 DLL alone.
