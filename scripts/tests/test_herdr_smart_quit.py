import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "herdr-smart-quit.sh"
PANE = "w1:p2"


@unittest.skipUnless(shutil.which("bash") and shutil.which("jq"), "requires bash and jq")
class SmartQuitTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.calls = root / "calls.jsonl"
        self.response = root / "response.json"
        fake = root / "herdr"
        fake.write_text(
            "#!" + shutil.which("python3") + "\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "args = sys.argv[1:]\n"
            "with open(os.environ['TEST_CALLS'], 'a') as log:\n"
            "    log.write(json.dumps(args) + '\\n')\n"
            "if args[:2] == ['pane', 'process-info']:\n"
            "    print(Path(os.environ['TEST_RESPONSE']).read_text())\n"
            "    sys.exit(int(os.environ.get('TEST_QUERY_EXIT', '0')))\n"
            "sys.exit(int(os.environ.get('TEST_ACTION_EXIT', '0')))\n"
        )
        fake.chmod(0o755)
        self.env = {
            **os.environ,
            "HERDR_BIN_PATH": str(fake),
            "HERDR_ACTIVE_PANE_ID": PANE,
            "HERDR_PANE_ID": "w9:p9",
            "TEST_CALLS": str(self.calls),
            "TEST_RESPONSE": str(self.response),
        }

    def run_script(self, response=None, raw=None):
        self.response.write_text(raw if raw is not None else json.dumps(response))
        self.calls.unlink(missing_ok=True)
        result = subprocess.run(
            ["bash", str(SCRIPT)],
            env=self.env,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        calls = (
            [json.loads(line) for line in self.calls.read_text().splitlines()]
            if self.calls.exists()
            else []
        )
        return result, calls

    def process_info(self, *names):
        return {
            "result": {
                "process_info": {
                    "pane_id": PANE,
                    "foreground_processes": [{"name": name} for name in names],
                }
            }
        }

    def test_editors_receive_ctrl_q(self):
        for editor in (
            "vi",
            "vim",
            "nvim",
            "view",
            "gvim",
            "vimdiff",
            "nvimdiff",
            ".nvim-wrapped",
            "/nix/store/example/bin/vim",
            "NVIM",
        ):
            with self.subTest(editor=editor):
                result, calls = self.run_script(self.process_info(editor))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    calls,
                    [
                        ["pane", "process-info", "--pane", PANE],
                        ["pane", "send-keys", PANE, "ctrl+q"],
                    ],
                )

    def test_other_programs_close_original_target(self):
        for program in ("bash", "nu", "fish", "python3", "pi", "nvim-helper"):
            with self.subTest(program=program):
                result, calls = self.run_script(self.process_info(program))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(calls[-1], ["pane", "close", PANE])
                self.assertEqual(len(calls), 2)

    def test_editor_in_foreground_pipeline_is_preserved(self):
        result, calls = self.run_script(self.process_info("tee", "nvim"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[-1], ["pane", "send-keys", PANE, "ctrl+q"])

    def test_no_active_target_does_not_fall_back_to_inherited_pane(self):
        del self.env["HERDR_ACTIVE_PANE_ID"]
        result, calls = self.run_script(self.process_info("bash"))
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [])

    def test_unknown_process_info_never_closes(self):
        mismatched = self.process_info("bash")
        mismatched["result"]["process_info"]["pane_id"] = "w2:p3"
        invalid = self.process_info("bash")
        invalid["result"]["process_info"]["foreground_processes"] = {}
        for response in (
            None,
            {},
            {"error": {"code": "pane_not_found"}},
            self.process_info(),
            self.process_info(None),
            self.process_info(""),
            self.process_info(123),
            mismatched,
            invalid,
        ):
            with self.subTest(response=response):
                result, calls = self.run_script(response)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, [["pane", "process-info", "--pane", PANE]])
        result, calls = self.run_script(raw="not json")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [["pane", "process-info", "--pane", PANE]])

    def test_query_failure_never_closes(self):
        self.env["TEST_QUERY_EXIT"] = "1"
        result, calls = self.run_script(self.process_info("bash"))
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [["pane", "process-info", "--pane", PANE]])

    def test_forwarding_failure_does_not_fall_back_to_close(self):
        self.env["TEST_ACTION_EXIT"] = "1"
        result, calls = self.run_script(self.process_info("nvim"))
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls[-1], ["pane", "send-keys", PANE, "ctrl+q"])
        self.assertEqual(len(calls), 2)


if __name__ == "__main__":
    unittest.main()
