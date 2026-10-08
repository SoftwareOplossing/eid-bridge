# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
"""Check the extracted Windows app's browser startup and always-on logging, without a card."""
import argparse
import ctypes
import json
from pathlib import Path
import struct
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    args = parser.parse_args()
    app = args.app.resolve(strict=True)
    documents = ctypes.create_unicode_buffer(32768)
    if ctypes.windll.shell32.SHGetFolderPathW(None, 5, None, 0, documents) != 0:
        raise RuntimeError("Cannot resolve the current user's Documents folder")
    log = Path(documents.value) / "LetsPeppol eID Bridge/Logs/LetsPeppol-eID-Bridge.log"
    started = time.time()
    message = json.dumps({"command": "quit", "arguments": {}}).encode()
    result = subprocess.run(
        [str(app), "chrome-extension://gnmckgbandlkacikdndelhfghdejfido/", "--parent-window=0"],
        input=struct.pack("<I", len(message)) + message,
        capture_output=True, timeout=30,
    )
    # Do not print native stdout/stderr, which may contain personal data for other commands.
    if result.returncode:
        raise RuntimeError("Native browser startup failed")
    frames = []
    data = result.stdout
    while data:
        if len(data) < 4:
            raise RuntimeError("Truncated native message header")
        size = struct.unpack("<I", data[:4])[0]
        if not 0 < size <= len(data) - 4:
            raise RuntimeError("Invalid native message length")
        frames.append(json.loads(data[4:4 + size]))
        data = data[4 + size:]
    if len(frames) != 2 or not frames[0].get("version") or frames[1] != {}:
        raise RuntimeError("Unexpected browser startup/quit response")
    if not log.is_file() or log.stat().st_mtime < started - 2:
        raise RuntimeError("Always-on log was not updated")
    if "Quit requested, finishing" not in log.read_text(encoding="utf-8"):
        raise RuntimeError("Startup did not reach the expected log")
    print(json.dumps({"native_browser_startup": True, "version": frames[0]["version"],
                      "always_on_documents_logging": True, "card_or_pin_used": False}))


if __name__ == "__main__":
    main()
