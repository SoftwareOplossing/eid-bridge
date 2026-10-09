# Redistribution preparation

Version 1.1.0 selects the unchanged, timestamped ZETES-signed **5.2.0.6426**
DLL extracted from the official-hosted **test wrapper 5.2.0.6447**. The wrapper
version must not be used as the DLL version. This choice follows the owner's
instruction to retain the official signed DLL. It retains the application,
Qt/OpenSSL versions, logging, browser setup and upgrade identity.

Free Visual Studio Community 2022 17.14.41 and its C++/Windows SDK tools were
installed at the publisher's request for this MIT project. A local unmodified
PKCS#11 revision 6426 build passed. The entitlement record is in
`third-party/microsoft/community-entitlement.json`; Microsoft's component-specific
runtime terms are now shown for acceptance in the installer.

The complete candidate revision 6426 source archive, generated header, build/
replacement instructions, source copyright blocks and official Toolkit agreements
are packaged. Source inputs at revisions 6426/6447 match; the independent builds
are successful and match the vendor exports/imports. The vendor's exact source
mapping remains **strongly_supported_unverified**. Keep `public_release=false`
and `corresponding_middleware_source_verified=false`. A clean-Windows signing
check of the changed DLL is also pending; the earlier working DLL's hardware
results do not establish this new DLL's behavior.

See [middleware provenance](../third-party/belgian-eid/SOURCE.md) and
[release evidence](release-evidence-1.1.0.json). No upstream request was posted.

The following sections retain the 1.0.1 audit as historical evidence. Its selected
5.1.34 DLL and pending Community setup are superseded by the records above.

## Completed packaging work

- MIT notices for Web eID, libelectronic-id and Let's Peppol.
- Qt 6.11.2: all 17 shipped Qt DLLs/plugins matched to the official MSVC2022 x64
  SDK. Its SPDX dependency graph identifies 70 component records; the notice
  bundle retains their copyright, attribution, applicable licence texts and
  source-release licence alternatives. Exact qtbase/qtsvg source commits and
  archive hashes are recorded, with original build options and feature summaries.
- The SDK's separately supplied Mesa 11.2.2 DLL matched byte-for-byte, with the
  official Qt-supplied Brian Paul, Khronos and Boost notices preserved.
- OpenSSL 3.5.8: version verified from the packaged library; Apache 2.0 text,
  upstream copyright and source/build references retained.
- Belgian eID: the DLL matches the official signed installer exactly. Its four
  official Toolkit agreements are now included verbatim alongside the LGPL text.
  This closes the missing agreement notice, not the corresponding-source gap.
- Microsoft: release CRT DLLs are sourced from Visual Studio's redistributable
  directory. The official runtime and Community terms and redistribution-list
  references are packaged. The old Windows 8.1 Direct3D compiler copy is excluded;
  Qt uses the Windows 11 system compiler through QSystemLibrary instead.

The builder verifies Qt DLL hashes against the notice inventory and checks the
collected notice hashes. These are packaging checks only: there is no application
hash lock preventing replacement of LGPL libraries. The installed file manifest
records every packaged notice and binary. Read the component-specific records in
`third-party/qt`, `third-party/openssl`, `third-party/microsoft` and
`third-party/belgian-eid`.

## Historical 1.0.1 public-release requirements

1. Obtain authoritative exact source, Windows build instructions and incorporated
   notices for Belgian `beidpkcs11.dll` 5.1.34.6213, SHA-256
   `b3e5bbd5112b5ef55f4189bdf334c989abf99f27c1cfb3c2a3e784efd780cf93`.
   The official `BeidMW_64_5.1.34.6350.msi` proves binary provenance but does not
   map it to public source. No matching v5.1.34 tag was found. The upstream request
   is prepared in [middleware-source-request.md](middleware-source-request.md);
   the user asked to keep it local, and nothing was posted.
2. Record the publisher's valid Visual Studio runtime redistribution entitlement
   and applicable end-user/distributor terms. Community's free OSI open-source
   route is available for this MIT project; possessing its licence text is not
   proof of accepting/holding the licence. A paid signing subscription is unrelated
   to this requirement. See [Microsoft record](../third-party/microsoft/README.md).

The middleware LGPL text is copied from the inspected public source snapshot
`cf2d593181c56de33198993278d64990292772c1`; that snapshot is not asserted to be
corresponding source for the official DLL. Its complete source/dependency notice
inventory remains dependent on authoritative source identification. Preserve
source access, build instructions, dynamic separation and applicable replacement/
relinking rights when this is resolved. Do not replace the working DLL merely
to guess a source mapping.

Unsigned distribution is a supported choice; Windows publisher/reputation warnings
may apply. Company signatures are optional under that choice. Signing does not
resolve open-source obligations. BUILD-INFO.json retains `public_release=false`
and `corresponding_middleware_source_verified=false` until the unresolved items
are closed. No middleware binary or MSI is tracked/published by this checkout.

## Recreate Qt notices

Fetch and extract the exact source and SDK archives identified by
`third-party/qt/notices/Qt-runtime-inventory.json`. Preserve the SDK's `sbom`,
`config_qtbase.*`, `config_qtsvg.*` and `opengl32sw.dll`. Save the official
Qt 6.11 Mesa attribution page as HTML, then run:

```powershell
python poc/scripts/collect-qt-notices.py --sdk build/license-audit/qt-sdk --sources build/license-audit/qt-source --runtime build/installer-help-app-runtime --output third-party/qt/notices --mesa-notice build/license-audit/mesa-qt-notice.html --archives build/license-audit
```

Review regenerated changes before using a new dependency version. Windows archive
permissions may require an elevated read; this does not change the source.

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
