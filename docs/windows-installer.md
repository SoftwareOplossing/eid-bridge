# Windows installer

The current professional candidate is
`build/installer/LetsPeppol-eID-Bridge-1.1.0-windows-x64-unsigned-candidate.msi`.
The product name and customer instructions no longer say "Test". Its stable
upgrade identity, browser registrations, extension requests, logging and runtime
are retained. It uses the official signed Belgian DLL 5.2.0.6426, rather than
the containing test wrapper's 5.2.0.6447 version. The complete candidate source
archive and rebuild/replacement instructions are bundled. This is an unsigned
private release candidate while exact vendor source mapping and signing acceptance
of the changed DLL are established. Free Visual Studio Community is now installed
for this MIT project's runtime redistribution route. Qt/Mesa/OpenSSL
notices and official middleware agreements are included. Signing is optional
when choosing unsigned distribution. See
[company signing](company-code-signing.md) and [release status](release-process.md).
The earlier test packages below are retained as historical evidence.

`build/installer/LetsPeppol-eID-Bridge-0.1.3-windows-x64-test.msi` is an unsigned
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
   double-click it. Existing official Web eID extensions can remain enabled.
3. Restart Edge and use the existing onboarding page. The installer registers
   `eu.webeid` automatically; no helper or separate middleware installation is
   needed. Edge is the tested browser; Chrome/Firefox registration is included
   but their integration has not been exercised.

Version 0.1.1 requests installation of the official Edge and Chrome extensions
from their stores using the same 32-bit registry mechanism as upstream Web eID.
Restart the browser and accept its enable/confirmation prompt. The installer does
not bypass that prompt or introduce force-install policies. Internet access is
required; existing browser policies and a previously rejected/uninstalled external
extension can prevent installation. Store links in README.txt provide recovery.
Firefox remains a manual store install in this version.

Version 0.1.3 simplifies Finish to a reminder to save work, restart the browser
and enable Web eID when prompted. A checked Finish option opens Let's Peppol
onboarding through the default URL handler. The installer leaves browser
selection to the website, which can identify the browser actually visiting it.
It does not terminate browser processes; restart remains a user action.

Launch the MSI normally and approve the machine installation's administrator
prompt. The optional onboarding launch belongs to the UI session. Maintenance,
uninstall, silent installs and an unchecked Finish option do not launch anything.
Extension requests cover both Edge and Chrome. There is no default-browser
registry search, new helper executable or upstream application change.

Local changes in `C:\LetsPeppol\letspeppol\app\ui` add one shared Web eID setup
component to onboarding and email confirmation. An extension-unavailable error
offers the visiting browser's official store (or a choice for unknown browsers).
A native-unavailable error offers desktop-application setup guidance instead.
Cancellation/card errors retain existing handling. Store links open in a new tab;
email confirmation reminds users to reopen their email link after a reload or
restart because the token is deliberately removed from the URL. These website
changes are local and have not been deployed. Firefox installation remains manual.

Browser documentation: [Edge external installation](https://learn.microsoft.com/en-us/microsoft-edge/extensions/developer-guide/alternate-distribution-options),
[Chrome external installation and confirmation](https://developer.chrome.com/docs/extensions/how-to/distribute/install-extensions).
If automatic Firefox installation is chosen later, reuse the upstream
[Firefox installer helper](https://github.com/web-eid/wix-custom-action-firefox-extension-install)
after the user forks it. It merges the shared ExtensionSettings policy; do not
replace that entire value with a hard-coded Web eID-only policy.

An existing official store-installation request is preserved. A different source
is rejected. This MSI records ownership only for requests it creates, and removes
only those on uninstall; upgrade preserves that ownership. The browser controls
whether the extension is removed when its request disappears. Other extension
policies are not changed. No extension fork is needed for Edge/Chrome.

The native Help button, About/error support links and Windows help link point
to https://be.letspeppol.org/onboarding, including after changing UI language.

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

The user reports installing/uninstalling 0.1.0 worked on the test laptop.
The automated MSI checks do not perform an installation; the new extension
requests and upgrade still need a physical browser/installer check. Existing
card/signing/cancellation tests remain accepted.

## Build

The `Installer application (Windows x64)` workflow reuses the portable native build with
`ELECTRONIC_ID_BEID_MODULE_PATH=APP_DIRECTORY`. Download and extract its runtime
artifact and verify SHA256SUMS.txt. It intentionally contains no Belgian DLL.
Use PowerShell 7, .NET 8 and WiX 4.0.6 with its UI and Util extensions:

```powershell
dotnet tool install wix --version 4.0.6 --tool-path build/tools/wix
build/tools/wix/wix.exe extension add --global WixToolset.UI.wixext/4.0.6
build/tools/wix/wix.exe extension add --global WixToolset.Util.wixext/4.0.6
poc/scripts/build-installer.ps1 `
  -RuntimeDirectory build/installer-help-app-runtime `
  -MiddlewareDll build/release-evidence/beid-5.2.0.6447/middleware-x64/File/beidpkcs11_64.dll `
  -MiddlewareSha256 871dd692ac8d77368758679a835d0262b33f0565580c081fb8066e0d14fcf2ad `
  -MiddlewareProvenance third-party/belgian-eid/official-5.2.0-provenance.json `
  -MiddlewareSourceArchive build/release-evidence/beid-5.2.0.6447/source-6426-built/eid-mw-5abf0ca70280320e79371faf207f427e1b852b1b-source.zip `
  -ReleaseEvidence docs/release-evidence-1.1.0.json `
  -Wix build/tools/wix/wix.exe
powershell.exe -NoProfile -ExecutionPolicy Bypass -File poc/tests/test_installer.ps1 -Msi build/installer/LetsPeppol-eID-Bridge-1.1.0-windows-x64-unsigned-candidate.msi
```

The builder requires NATIVE-BUILD.json for the executable-directory native build,
checks its executable hash and the selected middleware hash/signature, stages
only runtime files, and generates separate WiX file/host fragments. Fixture
mode is only for testing authoring: its output is named FIXTURE-NOT-FOR-USE and
must never be handed to a tester. The upstream installer source is unchanged.

Recreate the candidate source archive with `poc/scripts/build-beid-source.ps1`
against a clean, full-history revision 6426 checkout. Its generated archive hash
is recorded alongside the independently built comparison DLL; retain the archive
identified in the provenance record when reproducing this exact candidate.
The source archive contains all 1672 tracked files plus the generated header.
`-PublicRelease` remains unavailable for an unverified source classification,
even if a release-evidence file asserts completed hardware tests. Use the final
public filename only after the recorded source, binary-specific clean-Windows
signing and publisher-entitlement requirements are satisfied.

For cabinet verification, `wix msi decompile` with `-x` extracts actual payload
files. Pass its File directory to `poc/tests/test_installer_payload.ps1` along
with the MSI and a new OutputDirectory. Then run `test_installer_startup.py`
against the reconstructed web-eid.exe; it requests only version/quit and checks
the Documents log. WiX 4's decompiler can warn about MsiLockPermissionsEx while
extracting; the independent MSI-table test checks the actual ACL row.

The MSI-table test checks the onboarding target, launch ordering, checkbox
opt-out, UI-only action and maintenance/uninstall exclusion without launching
a browser or changing the system. The Finish screen still needs a physical
install/upgrade check on the test laptop. Website verification uses focused
Vitest recovery/rendering tests and a Vite production build. Pre-existing invoice
translation omissions/order problems prevent a clean whole-project translation
lint; new setup messages are validated in all four languages.

BUILD-INFO.json, NATIVE-BUILD.json, SHA256SUMS.txt and licence notices are included
in the package. This is not a public production release: matching Belgian DLL source remains unresolved and the publisher must record
Microsoft redistribution entitlement. Unsigned distribution is a supported choice. See [licensing](licensing.md) and [release gates](release-process.md).
