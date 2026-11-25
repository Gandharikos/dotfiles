import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import yaml

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/adguardhome-prepare.py"
spec = importlib.util.spec_from_file_location("adguard_prepare", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AdGuardPrepareTests(unittest.TestCase):
    def test_credentials_and_seed_preserve_user_exceptions_and_updates(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config, credential, seed = (root / name for name in ("config.yaml", "users.json", "seed"))
            config.write_text(yaml.safe_dump({"user_rules": ["@@||allowed.example^"], "dns": {"port": 53}, "filters": [{"id": 2}]}))
            users = [{"name": "johnson", "password": "$2b$12$" + "a" * 53}]
            credential.write_text(json.dumps(users))
            seed.write_text("0.0.0.0 blocked.example\n")
            old_cache = root / "data/filters/1.txt"
            old_cache.parent.mkdir(parents=True)
            old_cache.write_text("0.0.0.0 old-variant.example\n")
            module.prepare(config, credential, seed)
            self.assertEqual(old_cache.read_text(), "0.0.0.0 old-variant.example\n")
            parsed = yaml.safe_load(config.read_text())
            self.assertEqual(parsed["users"], users)
            self.assertEqual(parsed["user_rules"], ["@@||allowed.example^"])
            self.assertEqual(config.stat().st_mode & 0o777, 0o600)
            cache = root / "data/filters/2.txt"
            self.assertEqual(cache.read_text(), seed.read_text())
            cache.write_text("0.0.0.0 newer.example\n")
            module.prepare(config, credential, seed)
            self.assertEqual(cache.read_text(), "0.0.0.0 newer.example\n")

    def test_repository_credentials_are_encrypted_and_host_scoped(self):
        root = SCRIPT.parent.parent
        document = yaml.safe_load((root / "secrets/services/adguardhome.yaml").read_text())
        self.assertEqual(set(document) - {"sops"}, {"admin_password", "users"})
        for field in ("admin_password", "users"):
            self.assertTrue(document[field].startswith("ENC[AES256_GCM,"))
        groups = document["sops"].get("key_groups", [document["sops"]])
        self.assertEqual(len(groups), 1)
        self.assertEqual({item["recipient"] for item in groups[0]["age"]}, {
            "age1dru9s2hakwc4zjzh64z35nkt7uemgq4xc0vz5v5m8s2juy0edugs5esp5j",
            "age14wxne5fglt8x7rhxey4jx3uvjvawwrlckjwaal8tmf474gtv4vks7nm0ws",
        })
        self.assertEqual([item["fp"] for item in groups[0]["pgp"]], ["E23E274D412D4C761A871B1E776C7FC245E58F55"])

    def test_invalid_credentials_fail_closed_without_leaking_or_publishing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config, credential, seed = (root / name for name in ("config.yaml", "users.json", "seed"))
            original = "dns: {port: 53}\n"
            config.write_text(original)
            seed.write_text("0.0.0.0 blocked.example\n")
            for invalid in ([], {}, [{"name": "johnson", "password": "private-sensitive-value"}], "invalid-private-sensitive-value"):
                credential.write_text(json.dumps(invalid))
                result = subprocess.run([sys.executable, str(SCRIPT), str(config), str(credential), str(seed)], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("private-sensitive-value", result.stdout + result.stderr)
                self.assertEqual(config.read_text(), original)
                self.assertFalse((root / "data/filters/1.txt").exists())


if __name__ == "__main__":
    unittest.main()
