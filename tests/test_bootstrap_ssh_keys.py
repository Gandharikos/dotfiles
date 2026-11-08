import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/bootstrap-ssh-keys.sh"


@unittest.skipUnless(shutil.which("bash") and shutil.which("ssh-keygen"), "requires bash and ssh-keygen")
class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.ssh = self.home / ".ssh"
        self.etc = self.root / "etc-ssh"
        self.core = self.root / "core"
        self.bin = self.root / "bin"
        self.tmp = self.root / "tmp"
        for directory in (self.ssh, self.etc, self.core, self.bin, self.tmp):
            directory.mkdir(parents=True)
        self.keys = {}
        for label, name in (("user", "id_ed25519"), ("host", "test-host")):
            key = self.root / label
            subprocess.run(
                ["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(key)],
                check=True,
                capture_output=True,
            )
            self.keys[label] = key
            (self.core / f"{name}.pub").write_bytes(key.with_suffix(".pub").read_bytes())
            (self.core / f"{name}.yaml").write_text("fixture: not a real encrypted secret\n")
        self.destinations = (
            self.ssh / "id_ed25519",
            self.etc / "ssh_host_ed25519_key",
            self.etc / "ssh_host_ed25519_key.pub",
        )
        for path in self.destinations:
            path.write_text("previous " + path.name)
        self.previous = {path: path.read_bytes() for path in self.destinations}
        self.calls = self.root / "calls.jsonl"
        self.env = {
            **os.environ,
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "HOME": str(self.home),
            "TMPDIR": str(self.tmp),
            "TEST_ROOT": str(self.root),
            "TEST_CALLS": str(self.calls),
        }
        for name, body in {
            "sops": '''
args = sys.argv[1:]
assert args[:3] == ['-d', '--extract', '["data"]']
label = 'user' if Path(args[3]).name == 'id_ed25519.yaml' else 'host'
sys.stdout.write((root / label).read_text())
if os.environ.get('TEST_DECRYPT_FAIL') == label:
    sys.exit(1)
''',
            "sudo": '''
args = sys.argv[1:]
with open(os.environ['TEST_CALLS'], 'a') as log:
    log.write(json.dumps(args) + '\\n')
if args == ['-v']:
    sys.exit(int(os.environ.get('TEST_SUDO_FAIL', '0')))
if args[0] == 'install' and '-m' in args and '600' in args and os.environ.get('TEST_INSTALL_FAIL'):
    sys.exit(1)
args = [str(root / 'etc-ssh') + arg[len('/etc/ssh'):] if arg.startswith('/etc/ssh') else arg for arg in args]
sys.exit(subprocess.run(args, check=False).returncode)
''',
        }.items():
            wrapper = self.bin / name
            wrapper.write_text(
                f"#!{sys.executable}\n"
                "import json, os, subprocess, sys\nfrom pathlib import Path\n"
                "root = Path(os.environ['TEST_ROOT'])\n" + body
            )
            wrapper.chmod(0o755)

    def run_bootstrap(self, host="test-host"):
        return subprocess.run(
            ["bash", str(SCRIPT), str(self.core), host],
            env=self.env,
            capture_output=True,
            text=True,
            timeout=20,
            check=False,
        )

    def assert_preserved(self, result):
        self.assertNotEqual(result.returncode, 0)
        for path, content in self.previous.items():
            self.assertEqual(path.read_bytes(), content)
        self.assertEqual(list(self.tmp.iterdir()), [])
        self.assertEqual(list(self.ssh.glob(".id_ed25519.*")), [])
        self.assertEqual(list(self.etc.glob(".bootstrap-ssh.*")), [])

    def test_decryption_failure_preserves_all_existing_keys(self):
        for label in ("user", "host"):
            with self.subTest(label=label):
                self.env["TEST_DECRYPT_FAIL"] = label
                self.assert_preserved(self.run_bootstrap())
                self.assertFalse(self.calls.exists())

    def test_invalid_private_key_preserves_existing_keys(self):
        self.keys["host"].write_text("not an SSH key")
        self.assert_preserved(self.run_bootstrap())
        self.assertFalse(self.calls.exists())

    def test_public_key_mismatch_preserves_existing_keys(self):
        (self.core / "test-host.pub").write_bytes((self.core / "id_ed25519.pub").read_bytes())
        self.assert_preserved(self.run_bootstrap())
        self.assertFalse(self.calls.exists())

    def test_missing_public_key_preserves_existing_keys(self):
        (self.core / "test-host.pub").unlink()
        self.assert_preserved(self.run_bootstrap())
        self.assertFalse(self.calls.exists())

    def test_sudo_failure_preserves_existing_keys(self):
        self.env["TEST_SUDO_FAIL"] = "1"
        self.assert_preserved(self.run_bootstrap())

    def test_staging_failure_preserves_existing_keys(self):
        self.env["TEST_INSTALL_FAIL"] = "1"
        self.assert_preserved(self.run_bootstrap())

    def test_invalid_host_is_rejected_before_decryption(self):
        self.assert_preserved(self.run_bootstrap("../other-host"))
        self.assertFalse(self.calls.exists())

    def test_success_uses_atomic_replacement_and_private_permissions(self):
        # Open descriptors keep the old inode only if the file is renamed, not truncated.
        descriptors = [path.open("rb") for path in self.destinations]
        for descriptor in descriptors:
            self.addCleanup(descriptor.close)
        result = self.run_bootstrap()
        self.assertEqual(result.returncode, 0, result.stderr)
        expected = [
            self.keys["user"].read_bytes(),
            self.keys["host"].read_bytes(),
            (self.core / "test-host.pub").read_bytes(),
        ]
        for path, content, descriptor, mode in zip(self.destinations, expected, descriptors, (0o600, 0o600, 0o644)):
            self.assertEqual(path.read_bytes(), content)
            self.assertEqual(descriptor.read(), self.previous[path])
            self.assertEqual(path.stat().st_mode & 0o777, mode)
        self.assertEqual(self.ssh.stat().st_mode & 0o777, 0o700)
        self.assertEqual(list(self.tmp.iterdir()), [])
        self.assertEqual(list(self.ssh.glob(".id_ed25519.*")), [])
        self.assertEqual(list(self.etc.glob(".bootstrap-ssh.*")), [])
        for label in ("user", "host"):
            self.assertNotIn(self.keys[label].read_text(), result.stdout + result.stderr)
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()]
        self.assertFalse(any(call[0] in ("systemctl", "service") for call in calls))


if __name__ == "__main__":
    unittest.main()
