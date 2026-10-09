# Belgian eID binary provenance and source status

The selected unmodified Windows x64 DLL reports **5.2.0.6426**, not the wrapper's
5.2.0.6447. It is the regular `beidpkcs11_64.dll` in `BeidMW_64.msi`, extracted
without executing the [official-hosted test QuickInstaller](https://dist.eid.belgium.be/releases/test_BeidSignApp/Belgium%20eID-QuickInstaller%205.2.0.6447_1.1.24.exe).
Its installed name is `beidpkcs11.dll`. The wrapper, nested MSI and DLL have
valid timestamped ZETES SA Authenticode signatures. Hashes, extraction chain,
architecture, imports, exports and signature evidence are retained in
`official-5.2.0-provenance.json` and `checksums.txt`.

The owner selected this vendor DLL rather than substituting a source-built DLL.
The test distribution URL does not establish upstream production approval or
government endorsement. No official middleware installer is run by the bridge.

## Candidate corresponding source

Source mapping is **strongly_supported_unverified**. A vendor binary/source
attestation has not been obtained. The public source is
<https://github.com/Fedict/eid-mw>.

- Commit `5abf0ca70280320e79371faf207f427e1b852b1b` has full-history revision
  count 6426 and base version 5.2.0. It precedes the DLL's September 8, 2026 PE
  timestamp and fixes a PKCS#11 reader notification overflow.
- The owner's commit `5b2d101d09fcdb550098de1196cd64f82b431744` has count 6447.
  Its VS2022 PKCS#11 project, complete PKCS#11 source tree, SDK v240 headers
  and version generator inputs have identical Git object IDs to revision 6426.
  The generated revision/version header is different.
- An independent Windows build of the unmodified 6447 source passed. The DLL
  has the same 69 PKCS#11 exports, Windows import set, AMD64 architecture and
  linker version 14.44. Binary sections are not identical; no byte-identical
  reproduction or vendor checkout attestation is claimed.
- Public upstream CI around September 7–9 contains documentation and metadata
  checks, rather than a Windows DLL build record identifying this binary.

`licenses/Belgian-eID-source.zip` supplies the complete **candidate** revision
6426 tree with its generated version header for offline rebuilding. See
`Belgian-eID-build.md` for compiler prerequisites, rebuilding and DLL replacement.
It includes source, projects, scripts, resources, bundled LibTomCrypt hash
implementations and OASIS headers. Microsoft OS/compiler dependencies are
separate system/compiler libraries. Source completeness for this candidate does
not by itself prove that it corresponds to the selected vendor binary.

`LICENSE` retains the upstream LGPL notice, with full LGPLv3/GPLv3 texts and
`PKCS11-source-notices.txt` installed separately. The latter preserves source
copyright/licence blocks, including bundled dependency notices. The four
`Toolkit-agreement-*.rtf` files are byte-identical to those in this new official
MSI; all are retained verbatim. There is no middleware signature/hash lock at
application runtime preventing a compatible LGPL library replacement.

The installer remains a private release candidate while exact source mapping
and acceptance of this changed DLL remain pending. No vendor DLL or installer
is tracked in Git. See `docs/licensing.md` and `docs/release-process.md`.

## Historical binary

The earlier private candidate used DLL 5.1.34.6213 from
`BeidMW_64_5.1.34.6350.msi`. Its source mapping remained unresolved. The previous
request in `docs/middleware-source-request.md` is retained for history; no request
was posted to upstream. Its hashes must not be used for the selected 5.2.0 DLL.
