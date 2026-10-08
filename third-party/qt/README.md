# Qt runtime source and notices

Qt 6.11.2 is dynamically linked and unmodified, used under LGPL v3. Copyright,
component attribution and licence texts are in `Qt/Qt-THIRD-PARTY-NOTICES.txt`.
The LGPL/GPL texts are also provided separately. These notices contain licence
alternatives and a conservative source-release superset; not every alternative
or listed licence governs the distributed program.

The collector matched all 17 Qt DLLs/plugins against the official Windows
MSVC2022 x64 SDK version `6.11.2-0-202608131017`. The SDK's SPDX dependency graph
selects 70 component records. Mesa 11.2.2 is supplied separately by that SDK;
its identical `opengl32sw.dll` has its own notices. The installed inventory lists
file hashes, exact source commits, official archive hashes and selected records.

Exact corresponding Qt sources, including incorporated dependencies:

- https://download.qt.io/archive/qt/6.11/6.11.2/submodules/qtbase-everywhere-src-6.11.2.tar.xz
- https://download.qt.io/archive/qt/6.11/6.11.2/submodules/qtsvg-everywhere-src-6.11.2.tar.xz

Official binary SDK and SBOM:
https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt6_6112/qt6_6112_msvc2022_64/

Build instructions: https://doc.qt.io/qt-6/build-sources.html
The SDK's original configure options and feature summaries are preserved in
`Qt/build-records`. They identify MSVC 19.44.35227.0, shared-library builds and
bundled components; absolute SDK-builder paths must be adapted to a local setup.
For an open-source rebuild, use the LGPL option and accepted open-source terms.
The application source/build workflow is https://github.com/SoftwareOplossing/eid-bridge;
`NATIVE-BUILD.json` records the exact application/library build commits.

Compatible modified Qt libraries may replace the installed shared DLLs/plugins.
Installation in Program Files requires administrator access; the application
performs no Qt hash lock or signature restriction. Retain ABI compatibility,
including architecture, exports and plugin layout. Uninstall/reinstall or upgrade
can replace locally modified files, so keep a separate copy of modifications.
The applicable LGPL rights, including debugging library modifications, remain.

Regenerate the notices from extracted official archives with
`poc/scripts/collect-qt-notices.py`; see `docs/licensing.md` for the command.
