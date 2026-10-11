import importlib.util
import os
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


MODULE = Path(__file__).resolve().parents[2] / "modules/nixos/services/selfhosted/common/backup-health.py"
spec = importlib.util.spec_from_file_location("backup_health", MODULE)
health = importlib.util.module_from_spec(spec)
spec.loader.exec_module(health)


def usage(**overrides):
    values = dict(f_blocks=1000, f_bfree=800, f_bavail=750, f_frsize=4096,
                  f_files=1000, f_ffree=900, f_favail=900, f_flag=0)
    values.update(overrides)
    return SimpleNamespace(**values)


class DiskStatusTests(unittest.TestCase):
    def status(self, **overrides):
        with patch.object(health.os, "statvfs", return_value=usage(**overrides)):
            return health.disk_status("/", 85)

    def test_counts_only_unprivileged_available_space(self):
        result = self.status(f_bfree=400, f_bavail=0)
        self.assertEqual(result["used_percent"], 100)
        self.assertEqual(result["available_bytes"], 0)
        self.assertFalse(result["ok"])

    def test_healthy_disk(self):
        result = self.status()
        self.assertEqual(result["used_percent"], 22)
        self.assertEqual(result["available_bytes"], 750 * 4096)
        self.assertTrue(result["ok"])

    def test_warning_threshold_is_inclusive(self):
        self.assertFalse(self.status(f_bfree=150, f_bavail=150)["ok"])
        self.assertTrue(self.status(f_bfree=160, f_bavail=160)["ok"])

    def test_inode_exhaustion(self):
        result = self.status(f_ffree=0, f_favail=0)
        self.assertEqual(result["inode_used_percent"], 100)
        self.assertFalse(result["ok"])

    def test_filesystem_without_inode_accounting(self):
        result = self.status(f_files=0, f_ffree=0, f_favail=0)
        self.assertIsNone(result["inode_used_percent"])
        self.assertTrue(result["ok"])

    def test_read_only_service_namespace_is_not_host_read_only(self):
        self.assertTrue(self.status(f_flag=os.ST_RDONLY)["ok"])

    def test_invalid_or_missing_filesystem_fails_health(self):
        self.assertFalse(self.status(f_blocks=0, f_bfree=0, f_bavail=0)["ok"])
        with patch.object(health.os, "statvfs", side_effect=FileNotFoundError("missing disk")):
            self.assertFalse(health.disk_status("/missing", 85)["ok"])


class BackupHealthTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.success = Path(self.temp.name) / "last-success"
        self.dump = Path(self.temp.name) / "dump.sql.zst"
        self.success.write_text("1000\n")
        self.dump.write_bytes(b"fixture")

    def collect(self, disks=None):
        disks = disks or {"/": usage()}
        with patch.object(health.os, "statvfs", side_effect=lambda path: disks[path]):
            return health.collect_health(self.success, self.dump, 3600, 85, list(disks), now=2000)

    def test_healthy_and_preserves_root_keys(self):
        result = self.collect()
        self.assertTrue(result["ok"])
        self.assertTrue(result["checks"]["root_disk_ok"])
        self.assertEqual(result["checks"]["root_disk_used_percent"], 22)

    def test_full_data_volume_fails_even_with_healthy_root(self):
        result = self.collect({"/": usage(), "/var/lib": usage(f_bfree=0, f_bavail=0)})
        self.assertFalse(result["ok"])
        self.assertTrue(result["checks"]["root_disk_ok"])
        self.assertFalse(result["checks"]["disks_ok"])

    def test_stale_invalid_and_future_success_markers(self):
        for value in ["-5000", "bad", "3000"]:
            with self.subTest(value=value):
                self.success.write_text(value)
                self.assertFalse(self.collect()["ok"])

    def test_missing_success_marker(self):
        self.success.unlink()
        self.assertFalse(self.collect()["ok"])

    def test_empty_and_missing_postgresql_dump(self):
        self.dump.write_bytes(b"")
        self.assertFalse(self.collect()["ok"])
        self.dump.unlink()
        self.assertFalse(self.collect()["ok"])


if __name__ == "__main__":
    unittest.main()
