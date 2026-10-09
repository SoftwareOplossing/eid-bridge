# Version 1.1.0 release readiness — 2026-10-09

The completed public Windows 11 x64 installer is
`LetsPeppol-eID-Bridge-1.1.0-windows-x64-unsigned.msi`, 39,552,430 bytes.
SHA-256: `827c8c948a9791d5aeacc2a493e4ac0898f52db7690b01eb3e382ae660203936`.
It is ready for distribution under the publisher's selected unsigned route.
Download assets are assembled in `build/release/1.1.0`; no GitHub release,
website deployment or upstream issue was created by the agent.

| Item | Result | Evidence |
| --- | --- | --- |
| Official DLL identity/signature | Pass | Unchanged AMD64 DLL 5.2.0.6426, valid timestamped ZETES signature; wrapper/MSI hashes and signature records retained |
| Source/build relationship | Verified | Owner reported confirmation from Thomas Charlier at Zetes identifying commit 5abf0ca70280320e79371faf207f427e1b852b1b; original correspondence not independently reviewed; public inventory and builds checked separately |
| Corresponding source completeness | Pass | Actual MSI archive contains all 1672 revision 6426 tracked files plus the generated version header; selected build inputs match Git blobs after line-ending normalization |
| Source availability | Included | Complete middleware source and offline build instructions included in MSI and provided as a separate download; exact Windows native app/library source exported together; dependency source references/notices retained |
| Notices | Pass for inspected inputs | MIT, Qt/Mesa, OpenSSL, LGPL/GPL, official Toolkit agreements, source copyright blocks and Microsoft terms included; new agreements match the official MSI |
| Library replacement | Preserved | Same dynamic app-directory loader, separate DLL and no application-time signature/hash lock; rebuild/replacement instructions included |
| Microsoft entitlement setup | Completed | Publisher authorized free Community 2022 for this MIT project; 17.14.41 C++/SDK installation completed with exit 0, no reboot; local project source build passed |
| Installer licence page | Pass | Windows RichTextBox parses the RTF and displays the complete Microsoft runtime terms faithfully, limited to that component |
| MSI packaging | Pass | WiX validation, MSI identity/architecture/conflict/upgrade/ACL/browser-request checks and all 103 actual CAB file hashes passed; no machine installation performed |
| Browser startup/logging | Pass | Extracted actual MSI app answers framed version/quit and updates Documents log automatically; version 2.11.0+0 |
| Packaged PKCS#11 initialization | Pass | Actual MSI DLL loads; C_GetFunctionList/C_Initialize/C_GetSlotList/C_Finalize return 0; no card present, no PIN used |
| New DLL clean-laptop signing | Pass — owner reported | Owner confirmed signature_verified: true after the requested 1.1.0 installer/installed-app check on the clean Windows laptop; no PIN or personal certificate data collected |
| Test-build suitability | Limited evidence | Official host path is test_BeidSignApp; no claim of vendor production approval, certification or government endorsement |
| Public packaging guard | Pass | Earlier negative checks rejected missing evidence, unverified source with positive hardware flags and a mismatched source archive; final accepted records produce public_release=true and no remaining requirements |
| Public distribution | Ready | `public_release=true`, `corresponding_middleware_source_verified=true`, release_candidate=false; unsigned company distribution selected, paid code signing not required |

The native executable, Qt/OpenSSL runtime and application behavior are unchanged.
Keep existing successful KYC/PDF, cancellation and card-removal evidence for those
unchanged parts. Backend certificate trust and transaction binding remain KYC
responsibilities; this upgrade introduces no new backend validation requirements.

The independent source builds are comparison artifacts, not the packaged DLL.
Non-identical signed/unsigned PE hashes alone are not a licensing failure;
exact corresponding-source identification remains a factual evidence question.
The accepted evidence scope is explicit in the source provenance record.

The earlier candidate and its report remain historical. The final public MSI
repackages the same tested app, vendor DLL and runtime files with the accepted
source confirmation and public release metadata. Browser startup/logging and
private DLL initialization were repeated using the final MSI's extracted files;
no new card/PIN test was needed for these metadata changes. Full native and
middleware source downloads, build/source information and SHA256SUMS.txt are
provided alongside the single customer installer.
