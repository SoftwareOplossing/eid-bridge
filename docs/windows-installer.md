# Private Windows installer

`build/installer/LetsPeppol-eID-Bridge-0.1.0-windows-x64-test.msi` is an unsigned
private Windows 11 x64 test package. It bundles the bridge, Qt/VC++/OpenSSL
runtimes and the tested Belgian PKCS#11 DLL. It installs under
`C:\Program Files\LetsPeppol eID Bridge` with administrator approval; no global
Belgian middleware or minidriver is installed. No new repository fork is needed.

## Install on the existing test laptop

1. As the Windows user who registered the portable PoC, run:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\LetsPeppolPoC\register-test-host.ps1 -Action Remove
   ```

2. Keep the PoC folder for rollback. Close Edge, copy the MSI to the laptop and
   double-click it. Keep the official Web eID extension enabled.
3. Restart Edge and use the existing onboarding page. The installer registers
   `eu.webeid` automatically; no helper or separate middleware installation is
   needed. Edge is the tested browser; Chrome/Firefox registration is included
   but their integration has not been exercised.

Always-on logs are in the current user's
`Documents\LetsPeppol eID Bridge\Logs\LetsPeppol-eID-Bridge.log`. Start menu
shortcuts open onboarding, instructions and the current user's Documents folder.

Uninstall through Settings > Apps > Installed apps. Own program files,
shortcuts and host registrations are removed; user logs remain. To return to
the PoC afterward, run the same helper with `-Action Install`. The MSI refuses
conflicting host registrations, including during removal if another application
has replaced one. It checks the installing user's HKCU and machine HKLM in both
views; it does not inspect other users' profiles. Co-installation with the
official Web eID native app is not supported.

The automated MSI checks do not perform an installation. Confirm installation,
uninstall and upgrade on a test laptop before claiming these operations work
on a physical target. Existing card/signing/cancellation tests remain accepted.

## Build

The `Installer application (Windows x64)` workflow reuses the portable native build with
`ELECTRONIC_ID_BEID_MODULE_PATH=APP_DIRECTORY`. Download and extract its runtime
artifact and verify SHA256SUMS.txt. It intentionally contains no Belgian DLL.
Use PowerShell 7, .NET 8 and WiX 4.0.6 with WixToolset.UI.wixext/4.0.6:

```powershell
dotnet tool install wix --version 4.0.6 --tool-path build/tools/wix
build/tools/wix/wix.exe extension add --global WixToolset.UI.wixext/4.0.6
poc/scripts/build-installer.ps1 -RuntimeDirectory build/installer-app-runtime -MiddlewareDll build/clean-pc-test-kit/beidpkcs11.dll -MiddlewareSha256 b3e5bbd5112b5ef55f4189bdf334c989abf99f27c1cfb3c2a3e784efd780cf93 -Wix build/tools/wix/wix.exe
powershell.exe -NoProfile -ExecutionPolicy Bypass -File poc/tests/test_installer.ps1 -Msi build/installer/LetsPeppol-eID-Bridge-0.1.0-windows-x64-test.msi
```

The builder requires NATIVE-BUILD.json for the executable-directory native build,
checks its executable hash and the selected middleware hash/signature, stages
only runtime files, and generates separate WiX file/host fragments. Fixture
mode is only for testing authoring: its output is named FIXTURE-NOT-FOR-USE and
must never be handed to a tester. The upstream installer source is unchanged.

For cabinet verification, `wix msi decompile` with `-x` extracts actual payload
files. Pass its File directory to `poc/tests/test_installer_payload.ps1` along
with the MSI and a new OutputDirectory. Then run `test_installer_startup.py`
against the reconstructed web-eid.exe; it requests only version/quit and checks
the Documents log. WiX 4's decompiler can warn about MsiLockPermissionsEx while
extracting; the independent MSI-table test checks the actual ACL row.

BUILD-INFO.json, NATIVE-BUILD.json, SHA256SUMS.txt and licence notices are included
in the package. This is not a public production release: it is unsigned, matching
Belgian DLL source remains unresolved, and dependency redistribution/notices
need completion. See [licensing](licensing.md) and [release gates](release-process.md).
