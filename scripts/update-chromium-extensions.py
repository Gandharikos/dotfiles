#!/usr/bin/env python3
"""Refresh the pinned Chromium extension versions and flat SHA-256 hashes."""

import argparse
import base64
import hashlib
import io
import json
import re
import struct
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "users/johnson/home/gui/browsers/chromium.nix"
ENTRY = re.compile(
    r'(?P<prefix>\bid = "(?P<id>[a-p]{32})";\s+version = ")'
    r'(?P<version>[^"\n]+)(?P<middle>";\s+hash = ")'
    r'(?P<hash>sha256-[A-Za-z0-9+/=]+)(?P<suffix>";)'
)
VERSION = re.compile(r"[0-9]+(?:\.[0-9]+){0,3}")
MAX_CRX_SIZE = 128 * 1024 * 1024


class ExtensionUnavailable(Exception):
    """The store has no CRX for this extension and browser version."""


def extension_version(data):
    if len(data) < 12 or data[:4] != b"Cr24":
        raise ValueError("Download is not a CRX file")
    crx_version, header_size = struct.unpack_from("<II", data, 4)
    if crx_version == 3:
        offset = 12 + header_size
    elif crx_version == 2 and len(data) >= 16:
        signature_size = struct.unpack_from("<I", data, 12)[0]
        offset = 16 + header_size + signature_size
    else:
        raise ValueError(f"Unsupported or truncated CRX header: {crx_version}")
    if offset >= len(data) or data[offset : offset + 4] != b"PK\x03\x04":
        raise ValueError("CRX contains no ZIP payload")
    with zipfile.ZipFile(io.BytesIO(data[offset:])) as archive:
        if archive.getinfo("manifest.json").file_size > 1024 * 1024:
            raise ValueError("Extension manifest exceeds size limit")
        manifest = json.loads(archive.read("manifest.json"))
    version = manifest.get("version")
    if not isinstance(version, str) or not VERSION.fullmatch(version):
        raise ValueError(f"Invalid extension version: {version!r}")
    return version


def download(extension_id, chromium_major):
    # Keep this URL in sync with the fetchurl expression in chromium.nix.
    url = (
        "https://clients2.google.com/service/update2/crx"
        "?response=redirect&acceptformat=crx2,crx3"
        f"&prodversion={chromium_major}"
        f"&x=id%3D{extension_id}%26installsource%3Dondemand%26uc"
    )
    for attempt in range(3):
        try:
            with urllib.request.urlopen(url, timeout=60) as response:
                if response.status == 204:
                    raise ExtensionUnavailable("Chrome Web Store returned HTTP 204")
                data = response.read(MAX_CRX_SIZE + 1)
            if len(data) > MAX_CRX_SIZE:
                raise ValueError("CRX exceeds download size limit")
            return data
        except (urllib.error.URLError, TimeoutError):
            if attempt == 2:
                raise
            time.sleep(2 ** (attempt + 1))


def update(source, chromium_major, fetch=download):
    matches = list(ENTRY.finditer(source))
    if not matches:
        raise ValueError("No pinned Chromium extensions found")
    ids = [match["id"] for match in matches]
    if len(set(ids)) != len(ids):
        raise ValueError("Duplicate extension IDs")
    replacements = {}
    for match in matches:
        extension_id = match["id"]
        try:
            data = fetch(extension_id, chromium_major)
            version = extension_version(data)
        except ExtensionUnavailable as error:
            print(
                f"warning: {extension_id}: {error}; keeping existing pin",
                file=sys.stderr,
            )
            replacements[extension_id] = match.group(0)
            continue
        except Exception as error:
            raise RuntimeError(f"Failed to update {extension_id}: {error}") from error
        digest = base64.b64encode(hashlib.sha256(data).digest()).decode("ascii")
        new_hash = f"sha256-{digest}"
        replacements[extension_id] = (
            f"{match['prefix']}{version}{match['middle']}{new_hash}{match['suffix']}"
        )
        if version != match["version"] or new_hash != match["hash"]:
            print(f"{extension_id}: {match['version']} -> {version} (hash refreshed)")
    return ENTRY.sub(lambda match: replacements[match["id"]], source)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--chromium-version",
        help="Override the Chromium version (default: evaluate the locked ymir package)",
    )
    args = parser.parse_args()
    version = args.chromium_version
    if version is None:
        version = subprocess.check_output(
            [
                "nix",
                "eval",
                "--raw",
                "--no-write-lock-file",
                ".#nixosConfigurations.ymir.config.home-manager.users.johnson.programs.chromium.package.version",
            ],
            cwd=ROOT,
            text=True,
        ).strip()
    if not VERSION.fullmatch(version):
        raise ValueError(f"Invalid Chromium version: {version!r}")
    source = CONFIG.read_text()
    result = update(source, version.split(".")[0])
    if result != source:
        # Never leave a partially updated list after a download/validation failure.
        CONFIG.write_text(result)
        print(f"Updated {CONFIG.relative_to(ROOT)}")
    else:
        print("Chromium extensions are already up to date")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(1)
