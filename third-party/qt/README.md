# Qt runtime in the private Windows test installer

Qt 6.11.2 is dynamically linked. The installer includes LGPL v3 and GPL v3
texts, copied verbatim from the Qt source tag:

- https://github.com/qt/qtbase/blob/v6.11.2/LICENSES/LGPL-3.0-only.txt
- https://github.com/qt/qtbase/blob/v6.11.2/LICENSES/GPL-3.0-only.txt

Qt source and build instructions:
https://download.qt.io/archive/qt/6.11/6.11.2/single/
https://doc.qt.io/qt-6/build-sources.html

The application source is https://github.com/SoftwareOplossing/eid-bridge
and records the Qt version and native build commit in NATIVE-BUILD.json.
The package preserves runtime notices supplied by vcpkg and any LICENSES
directories present in the Qt SDK. This is not a completed public-distribution
notice inventory: Qt's incorporated third-party components and Microsoft runtime
redistribution still need review. The private test MSI must not be published.
