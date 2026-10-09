# Version 1.1.0 release readiness — 2026-10-09

The selected package is the professional Windows 11 x64 installer candidate
`LetsPeppol-eID-Bridge-1.1.0-windows-x64-unsigned-candidate.msi`, 39,544,238 bytes.
SHA-256: `0be4cb3e713ab157c7f8f06041e47738c542454b3396cc6f40b45ff8f373db2a`.
It is private; no public installer, GitHub release or upstream issue was posted.

| Item | Result | Evidence |
| --- | --- | --- |
| Official DLL identity/signature | Pass | Unchanged AMD64 DLL 5.2.0.6426, valid timestamped ZETES signature; wrapper/MSI hashes and signature records retained |
| Source/build relationship | Pending exact mapping | `strongly_supported_unverified`; VS2022 source inputs identical at revisions 6426/6447, matching exports/imports, independent builds pass; no vendor attestation |
| Candidate source completeness | Pass | Actual MSI archive contains all 1672 revision 6426 tracked files plus the generated version header; selected build inputs match Git blobs after line-ending normalization |
| Source availability | Candidate packaged | Source ZIP and offline build instructions included in MSI; durable public release assets await source mapping/publish readiness |
| Notices | Pass for inspected inputs | MIT, Qt/Mesa, OpenSSL, LGPL/GPL, official Toolkit agreements, source copyright blocks and Microsoft terms included; new agreements match the official MSI |
| Library replacement | Preserved | Same dynamic app-directory loader, separate DLL and no application-time signature/hash lock; rebuild/replacement instructions included |
| Microsoft entitlement setup | Completed | Publisher authorized free Community 2022 for this MIT project; 17.14.41 C++/SDK installation completed with exit 0, no reboot; local project source build passed |
| Installer licence page | Pass | Windows RichTextBox parses the RTF and displays the complete Microsoft runtime terms faithfully, limited to that component |
| MSI packaging | Pass | WiX validation, MSI identity/architecture/conflict/upgrade/ACL/browser-request checks and all 103 actual CAB file hashes passed; no machine installation performed |
| Browser startup/logging | Pass | Extracted actual MSI app answers framed version/quit and updates Documents log automatically; version 2.11.0+0 |
| Packaged PKCS#11 initialization | Pass | Actual MSI DLL loads; C_GetFunctionList/C_Initialize/C_GetSlotList/C_Finalize return 0; no card present, no PIN used |
| New DLL clean-laptop signing | Pending | Owner asked to install this candidate and verify one signature using the existing check-signature tool; previous DLL's tests are historical |
| Test-build suitability | Limited evidence | Official host path is test_BeidSignApp; no claim of vendor production approval, certification or government endorsement |
| Public packaging guard | Pass | Rejects missing evidence, unverified source even with positive hardware flags, and a mismatched source archive |
| Public distribution | Pending | `public_release=false`, `corresponding_middleware_source_verified=false`; unsigned company distribution selected, paid code signing not required |

The native executable, Qt/OpenSSL runtime and application behavior are unchanged.
Keep existing successful KYC/PDF, cancellation and card-removal evidence for those
unchanged parts. Backend certificate trust and transaction binding remain KYC
responsibilities; this upgrade introduces no new backend validation requirements.

The independent source builds are comparison artifacts, not the packaged DLL.
Non-identical signed/unsigned PE hashes alone are not a licensing failure;
exact corresponding-source identification remains a factual evidence question.
The current builder retains the conservative source-verification distinction.
