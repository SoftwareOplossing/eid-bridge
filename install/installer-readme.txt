Let's Peppol eID Bridge - Windows 11 x64 test build

The MSI installs the native bridge, private Belgian eID module and runtime
dependencies under Program Files\LetsPeppol eID Bridge. Administrator approval
is needed. No global Belgian middleware or minidriver is installed.

Before upgrading from the portable PoC on this Windows user, remove its browser
host registration with the helper you already used:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\LetsPeppolPoC\register-test-host.ps1 -Action Remove
Keep the portable folder as your rollback copy. Close your browser before installation.
The installer refuses to replace another registered native host.

The installer requests the official Edge and Chrome Web eID extensions from
their stores. Restart the browser after installation and accept its prompt to
enable Web eID. Internet access is needed for the browser's download; existing
browser policies or a previously rejected extension can prevent installation.
The installer does not force-enable extensions or block other extensions.
Firefox still requires a manual store install. Store links for recovery:
Edge: https://microsoftedge.microsoft.com/addons/detail/gnmckgbandlkacikdndelhfghdejfido
Chrome: https://chromewebstore.google.com/detail/web-eid/ncibgoaomkmdpilpocfeponihegamlic
Firefox: https://addons.mozilla.org/firefox/addon/web-eid-webextension/
Only Edge has been exercised with the current Let's Peppol PoC.

The installer Finish screen reminds you to save your work and restart your
browser, and offers to open Let's Peppol onboarding. The website offers the
matching store link when Web eID is unavailable in the browser visiting the
page. Firefox installation remains manual. The installer does not close browser
windows or restart them automatically. Silent installs do not launch anything.
Launch the MSI normally as your own Windows user and approve its administrator
prompt.

Restart the browser and open https://be.letspeppol.org/onboarding . The Start menu
contains an onboarding link, these instructions and an Open Documents for logs
shortcut. From Documents, open LetsPeppol eID Bridge\Logs. The shortcut resolves
the current user's Documents folder even if a different administrator installed
the application.
Logging is always enabled at:
Documents\LetsPeppol eID Bridge\Logs\LetsPeppol-eID-Bridge.log
Review logs before sharing; do not share your PIN or identity/certificate data.

Uninstall from Windows Settings > Apps > Installed apps. The installer removes
its files, shortcuts and native-host registrations. Operational logs remain in
your Documents folder. Extension installation requests created by this MSI are
removed; requests that existed before installation are preserved. The browser
controls extension removal on its next start; you can also remove it manually
or install it directly from the store if you need it elsewhere.
To return to the PoC after uninstall, run register-test-host.ps1 -Action Install.

This is an unsigned private test installer, not a public production release.
Corresponding source for the tested Belgian DLL is still being established.
Do not publish this installer. Copyright/license notices, file hashes and build
metadata are installed beside the app. The upstream projects do not endorse it.

Help and onboarding: https://be.letspeppol.org/onboarding
