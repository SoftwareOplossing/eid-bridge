# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
"""Collect notices from the exact Qt SDK SBOM and matching source archives.

Inputs are extracted official archives; this script neither downloads nor builds
code. It verifies the runtime against the SDK before selecting its dependencies.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import html
import shutil


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def collect(sdk, sources, runtime, output, mesa_notice, archives):
    inventory = []
    sections = []
    licenses = {}
    selected_packages = []
    source_commits = {}
    for module in ("qtbase", "qtsvg"):
        source = sources / f"{module}-everywhere-src-6.11.2"
        sbom_file = sdk / "sbom" / f"{module}-6.11.2.spdx.json"
        sbom = json.loads(sbom_file.read_text(encoding="utf-8"))
        source_commits[module] = (source / ".tag").read_text().strip()
        if not any(p.get("downloadLocation", "").endswith("@" + source_commits[module]) for p in sbom["packages"]):
            raise ValueError(f"Source commit does not match SDK SBOM: {module}")
        packages = {p["SPDXID"]: p for p in sbom["packages"]}
        contains = {}
        depends = {}
        for r in sbom["relationships"]:
            table = contains if r["relationshipType"] == "CONTAINS" else depends
            if r["relationshipType"] in ("CONTAINS", "DEPENDS_ON"):
                table.setdefault(r["spdxElementId"], set()).add(r["relatedSpdxElement"])
        selected = set()
        for f in sbom["files"]:
            relative = f["fileName"].removeprefix("./")
            if not relative.endswith(".dll"):
                continue
            destination = relative.removeprefix("bin/").removeprefix("plugins/")
            candidate = runtime / destination
            if not candidate.is_file():
                continue
            original = sdk / relative
            if sha256(candidate) != sha256(original):
                raise ValueError(f"Runtime differs from official Qt SDK: {destination}")
            inventory.append({"file": destination, "sha256": sha256(candidate), "module": module})
            selected.update(p for p, children in contains.items() if f["SPDXID"] in children)
        pending = list(selected)
        while pending:
            for dependency in depends.get(pending.pop(), ()):
                if dependency in packages and dependency not in selected:
                    selected.add(dependency)
                    pending.append(dependency)
        seen_attributions = set()
        for package_id in sorted(selected):
            package = packages[package_id]
            selected_packages.append(package)
            sections.append("\n" + package["name"] + "\n" + "-" * 60 + "\n"
                            + package.get("copyrightText", "NOASSERTION") + "\n"
                            + package.get("licenseConcluded", "NOASSERTION") + "\n")
            comment = package.get("comment", "")
            match = re.search(r"/src_dir/" + module + r"/(\S*qt_attribution.json).*?Entry index: (\d+)", comment, re.S)
            if not match or match.groups() in seen_attributions:
                continue
            seen_attributions.add(match.groups())
            attribution_file = source / match[1]
            entries = json.loads(attribution_file.read_text(encoding="utf-8"), strict=False)
            entry = (entries if isinstance(entries, list) else [entries])[int(match[2])]
            sections.append(json.dumps(entry, ensure_ascii=False, indent=2) + "\n")
            files = entry.get("LicenseFiles", entry.get("LicenseFile", []))
            if isinstance(files, str):
                files = [files]
            for name in files:
                path = (attribution_file.parent / name).resolve(strict=True)
                if not path.is_relative_to(source.resolve()):
                    raise ValueError("License path outside source archive")
                try:
                    text = path.read_text(encoding="utf-8")
                except UnicodeDecodeError:
                    text = path.read_text(encoding="latin-1")
                licenses[f"{module}/{path.relative_to(source.resolve()).as_posix()}"] = text
        # Include the source release's SPDX licence texts, also covering entries
        # whose notice is in a source header rather than a separate LicenseFile.
        for path in (source / "LICENSES").glob("*.txt"):
            licenses[f"{module}/LICENSES/{path.name}"] = path.read_text(encoding="utf-8")
        for entry in sbom.get("hasExtractedLicensingInfos", []):
            licenses[f"{module}/{entry['licenseId']}"] = entry["extractedText"]
        # FreeType's overview points to these additional licence texts.
        if module == "qtbase":
            for name in ("FTL.TXT", "GPLv2.TXT"):
                path = source / "src/3rdparty/freetype/docs" / name
                licenses[f"{module}/FreeType/{name}"] = path.read_text(encoding="utf-8")
    expected = {p.relative_to(runtime).as_posix() for p in runtime.rglob("*.dll")
                if p.name.startswith("Qt6") or p.parent != runtime}
    actual = {f["file"] for f in inventory}
    if expected != actual:
        raise ValueError(f"Qt inventory mismatch: {expected ^ actual}")
    output.mkdir(parents=True, exist_ok=True)
    build_records = output / "build-records"
    build_records.mkdir(exist_ok=True)
    for module in ("qtbase", "qtsvg"):
        for suffix in ("opt", "summary"):
            shutil.copyfile(sdk / f"config_{module}.{suffix}", build_records / f"config_{module}.{suffix}")
    notice = ("Qt 6.11.2 Windows MSVC2022 x64 runtime notices\n"
              "Generated from the official binary SBOM and matching source archives.\n"
              "Component records below follow the shipped DLLs and their SDK dependency graph.\n"
              "Licence texts include alternatives and a conservative source-release superset;\n"
              "their presence does not mean every alternative or component is used.\n"
              "Qt is used under LGPL v3, dynamically linked and unmodified.\n")
    notice += "".join(sections)
    for name, content in sorted(licenses.items()):
        notice += "\n" + "=" * 72 + "\n" + name + "\n" + "=" * 72 + "\n" + content + "\n"
    (output / "Qt-THIRD-PARTY-NOTICES.txt").write_text(notice, encoding="utf-8", newline="\n")
    record = {"qt_version": "6.11.2", "sdk_version": "6.11.2-0-202608131017",
              "sdk_url": "https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt6_6112/qt6_6112_msvc2022_64/",
              "source_url": "https://download.qt.io/archive/qt/6.11/6.11.2/submodules/",
              "runtime_files": sorted(inventory, key=lambda x: x["file"]),
              "notice_sha256": sha256(output / "Qt-THIRD-PARTY-NOTICES.txt"),
              "sbom_sha256": {m: sha256(sdk / "sbom" / f"{m}-6.11.2.spdx.json") for m in ("qtbase", "qtsvg")},
              "packages": selected_packages}
    record["source_commits"] = source_commits
    # Qt's separately distributed Mesa DLL is outside the qtbase/qtsvg SBOMs.
    if sha256(runtime / "opengl32sw.dll") != sha256(sdk / "opengl32sw.dll"):
        raise ValueError("Mesa runtime differs from the official Qt SDK")
    page = mesa_notice.read_text(encoding="utf-8")
    blocks = re.findall(r"<pre[^>]*>(.*?)</pre>", page, re.S)
    if len(blocks) != 4:
        raise ValueError("Unexpected Mesa notice page structure; review its licences")
    mesa_text = ("Mesa llvmpipe 11.2.2, supplied as opengl32sw.dll by the Qt 6.11.2 SDK\n\n"
                 "Source of these verbatim notices:\n"
                 "https://doc.qt.io/qt-6.11/qt-attribution-llvmpipe.html\n\n")
    mesa_text += "\n\n".join(html.unescape(re.sub("<[^>]+>", "", b)) for b in blocks)
    (output / "Mesa-THIRD-PARTY-NOTICES.txt").write_text(mesa_text, encoding="utf-8", newline="\n")
    record["mesa"] = {"version": "11.2.2", "file": "opengl32sw.dll",
                      "sha256": sha256(runtime / "opengl32sw.dll"),
                      "notice_sha256": sha256(output / "Mesa-THIRD-PARTY-NOTICES.txt")}
    record["source_archive_sha256"] = {p.name: sha256(p) for p in sorted(archives.glob("*-everywhere-src-6.11.2.tar.xz"))}
    record["binary_archive_sha256"] = {p.name: sha256(p) for p in sorted(archives.glob("*.7z"))}
    (output / "Qt-runtime-inventory.json").write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Verified {len(inventory)} Qt DLLs; collected {len(selected_packages)} component records and {len(licenses)} licence texts.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("sdk", "sources", "runtime", "output", "mesa-notice", "archives"):
        parser.add_argument("--" + name, required=True, type=Path)
    args = parser.parse_args()
    collect(args.sdk, args.sources, args.runtime, args.output, args.mesa_notice, args.archives)
