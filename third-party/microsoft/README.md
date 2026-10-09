# Microsoft Visual C++ runtime

The installer copies these unmodified x64 release DLLs from the native build's
Visual Studio 2022 `VC/Redist/MSVC/*/x64/Microsoft.VC143.CRT` directory:

`concrt140.dll`, `msvcp140.dll`, `msvcp140_1.dll`, `msvcp140_2.dll`,
`msvcp140_atomic_wait.dll`, `msvcp140_codecvt_ids.dll`, `vccorlib140.dll`,
`vcruntime140.dll`, `vcruntime140_1.dll`, `vcruntime140_threads.dll`.

The recorded runtime version is 14.44.35211.0. Per-file hashes are supplied in
the installed `SHA256SUMS.txt`; the native build provenance is in `NATIVE-BUILD.json`.
The DLLs are separate proprietary dependencies, not covered by the application's
MIT licence or the Qt/middleware LGPL licences. They are not modified or signed
again. Debug/nonredistributable binaries are excluded.

Microsoft's [Visual Studio 2022 redistribution list](https://learn.microsoft.com/en-us/visualstudio/releases/2022/redistribution)
permits these release files to be distributed with an application by a validly
licensed Visual Studio user, subject to that product's terms. App-local deployment
is documented in [redistributing Visual C++ files](https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files).

The accompanying texts are extracted from Microsoft's official documents:

- [Visual C++ Runtime 2015–2022 terms](https://visualstudio.microsoft.com/license-terms/vs2022-cruntime/):
  [original DOCX](https://visualstudio.microsoft.com/wp-content/uploads/2021/09/Visual-C-Runtime-2015-2022-License-1.docx).
- [Visual Studio Community 2022 terms](https://visualstudio.microsoft.com/license-terms/vs2022-ga-community/):
  [original DOCX](https://visualstudio.microsoft.com/wp-content/uploads/2021/11/Visual-Studio-2022-Community-License-EN.docx).

Community permits organizational users to develop applications released under
OSI-approved licences, including this MIT application, without the usual
organizational user-count restriction. Its Distributable Code section grants
redistribution subject to requirements/restrictions, including protecting the
Microsoft code in distribution/end-user terms. Free Community licensing is an
available route. On 2026-10-09 the publisher explicitly chose and authorized
installation of Community 2022 for this MIT project. Version 17.14.41, the
C++ workload and Windows SDK were installed on the development PC; an unmodified
project middleware source build passed using these tools. The installed product
reports complete, launchable and no reboot required. See
`community-entitlement.json` for product identity, licence route and terms hash.
This records the selected entitlement rather than merely copying the terms.
The runtime EULA is also shown on the installer's licence page for users to
accept, applying only to Microsoft's separate component. MIT/LGPL rights are
preserved. Downstream distributors must maintain applicable terms and obtain
their own distribution rights. The runtime EULA alone is not the developer's
redistribution grant. Paid code signing remains a separate, optional choice.

The Windows 8.1 SDK `d3dcompiler_47.dll` previously copied by Qt deployment is
excluded from this Windows 11-only installer. Qt's `QRhiD3D::resolveD3DCompile`
uses `QSystemLibrary` to resolve the operating system's compiler. Windows system
components are not copied into this package.
