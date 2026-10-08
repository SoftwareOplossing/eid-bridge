Let's Peppol eID Bridge - Windows 11 x64 test build

The MSI installs the native bridge, private Belgian eID module and runtime
dependencies under Program Files\LetsPeppol eID Bridge. Administrator approval
is needed. No global Belgian middleware or minidriver is installed.

Before upgrading from the portable PoC on this Windows user, remove its browser
host registration with the helper you already used:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\LetsPeppolPoC\register-test-host.ps1 -Action Remove
Keep the portable folder as your rollback copy. Close Edge before installation.
The installer refuses to replace another registered native host.

Keep the official Web eID browser extension enabled. If it is not installed,
install it from your browser's store:
Edge: https://microsoftedge.microsoft.com/addons/detail/gnmckgbandlkacikdndelhfghdejfido
Chrome: https://chromewebstore.google.com/detail/web-eid/ncibgoaomkmdpilpocfeponihegamlic
Firefox: https://addons.mozilla.org/firefox/addon/web-eid-webextension/
Only Edge has been exercised with the current Let's Peppol PoC.

Restart the browser and open https://be.letspeppol.org/onboarding . The Start menu
contains an onboarding link, these instructions and an Open logs shortcut.
Logging is always enabled at:
Documents\LetsPeppol eID Bridge\Logs\LetsPeppol-eID-Bridge.log
Review logs before sharing; do not share your PIN or identity/certificate data.

Uninstall from Windows Settings > Apps > Installed apps. The installer removes
its files, shortcuts and native-host registrations. Operational logs remain in
your Documents folder. Keep the browser extension if you still need it elsewhere.
To return to the PoC after uninstall, run register-test-host.ps1 -Action Install.

This is an unsigned private test installer, not a public production release.
Corresponding source for the tested Belgian DLL is still being established.
Do not publish this installer. Copyright/license notices, file hashes and build
metadata are installed beside the app. The upstream projects do not endorse it.
