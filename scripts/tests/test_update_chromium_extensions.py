import base64
import hashlib
import importlib.util
import io
import json
import struct
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "update-chromium-extensions.py"
SPEC = importlib.util.spec_from_file_location("updater", SCRIPT)
updater = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(updater)


def crx(version="2.0.1", format_version=3):
    payload = io.BytesIO()
    with zipfile.ZipFile(payload, "w") as archive:
        archive.writestr("manifest.json", json.dumps({"version": version}))
    if format_version == 3:
        header = b"Cr24" + struct.pack("<II", 3, 4) + b"test"
    else:
        header = b"Cr24" + struct.pack("<III", 2, 3, 4) + b"keysign"
    return header + payload.getvalue()


def entry(extension_id="a" * 32):
    return (
        f'  # Keep this comment\n  {{ id = "{extension_id}";\n'
        '    version = "1.0";\n'
        f'    hash = "sha256-{base64.b64encode(bytes(32)).decode()}"; }}\n'
    )


class UpdateTests(unittest.TestCase):
    def test_crx_formats(self):
        for format_version in (2, 3):
            with self.subTest(format_version=format_version):
                self.assertEqual(
                    updater.extension_version(crx(format_version=format_version)),
                    "2.0.1",
                )

    def test_invalid_downloads(self):
        for data in (
            b"<html>Error</html>",
            b"Cr24",
            b"Cr24" + struct.pack("<II", 9, 0),
            b"Cr24" + struct.pack("<II", 3, 999999),
            crx('1.0"; malicious'),
        ):
            with self.subTest(data=data[:16]), self.assertRaises(ValueError):
                updater.extension_version(data)

    def test_update_and_idempotence(self):
        data = crx()
        with patch.object(updater, "download", return_value=data) as fetch:
            result = updater.update(entry(), "150", fetch=fetch)
            fetch.assert_called_once_with("a" * 32, "150")
            self.assertEqual(updater.update(result, "150", fetch=fetch), result)
        self.assertIn("# Keep this comment", result)
        self.assertIn('version = "2.0.1";', result)
        digest = base64.b64encode(hashlib.sha256(data).digest()).decode()
        self.assertIn(f'hash = "sha256-{digest}";', result)

    def test_empty_and_duplicate_entries_fail(self):
        for source in ("", entry() + entry()):
            with self.assertRaises(ValueError):
                updater.update(source, "150")

    def test_failed_download_never_writes_config(self):
        source = entry() + entry("b" * 32)
        with (
            patch.object(updater.CONFIG.__class__, "read_text", return_value=source),
            patch.object(updater.CONFIG.__class__, "write_text") as write,
            patch.object(
                updater.urllib.request, "urlopen", side_effect=ValueError("unavailable")
            ),
            patch("sys.argv", [str(SCRIPT), "--chromium-version", "150.0.1.0"]),
        ):
            with self.assertRaisesRegex(RuntimeError, "Failed to update"):
                updater.main()
            write.assert_not_called()

    def test_unavailable_extension_keeps_pin(self):
        source = entry() + entry("b" * 32)
        with patch.object(
            updater,
            "download",
            side_effect=[updater.ExtensionUnavailable("HTTP 204"), crx()],
        ) as fetch:
            result = updater.update(source, "150", fetch=fetch)
        self.assertTrue(result.startswith(entry()))
        self.assertIn('version = "2.0.1";', result)

    def test_http_204_is_unavailable(self):
        with patch.object(updater.urllib.request, "urlopen") as urlopen:
            urlopen.return_value.__enter__.return_value.status = 204
            with self.assertRaises(updater.ExtensionUnavailable):
                updater.download("a" * 32, "150")

    def test_download_url_matches_nix(self):
        with patch.object(updater.urllib.request, "urlopen") as urlopen:
            urlopen.return_value.__enter__.return_value.read.return_value = crx()
            updater.download("a" * 32, "150")
        self.assertEqual(
            urlopen.call_args.args[0],
            "https://clients2.google.com/service/update2/crx?response=redirect"
            "&acceptformat=crx2,crx3&prodversion=150"
            f"&x=id%3D{'a' * 32}%26installsource%3Dondemand%26uc",
        )


if __name__ == "__main__":
    unittest.main()
