import importlib.util
import pathlib
import subprocess
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "tailscale_wait", pathlib.Path(__file__).parents[1] / "scripts/tailscale-wait-running.py"
)
WAIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(WAIT)


def response(value):
    return subprocess.CompletedProcess([], 0, value)


class ReadinessTests(unittest.TestCase):
    @patch.object(WAIT.time, "sleep")
    @patch.object(WAIT.subprocess, "run")
    def test_waits_for_running_without_mutating_tailnet(self, run, sleep):
        run.side_effect = [
            response('{"BackendState":"NoState"}'),
            response('{"BackendState":"Starting"}'),
            response('{"BackendState":"Running"}'),
        ]
        self.assertTrue(WAIT.wait_running("/test/tailscale"))
        self.assertEqual(run.call_count, 3)
        self.assertEqual(sleep.call_count, 2)
        for call in run.call_args_list:
            self.assertEqual(call.args[0], ["/test/tailscale", "status", "--json"])
            self.assertEqual(call.kwargs["timeout"], 2)
            self.assertEqual(call.kwargs["stderr"], subprocess.DEVNULL)
            self.assertTrue(call.kwargs["check"])

    @patch.object(WAIT.time, "sleep")
    @patch.object(WAIT.subprocess, "run")
    def test_errors_and_invalid_states_exhaust_bounded_budget(self, run, sleep):
        failures = [
            OSError("socket unavailable"),
            subprocess.TimeoutExpired("status", 2),
            subprocess.CalledProcessError(1, "status"),
            response("not json"),
            response("[]"),
            response("null"),
            response("{}"),
            response('{"BackendState":"NeedsLogin"}'),
            response('{"BackendState":"Stopped"}'),
        ]
        for failure in failures:
            with self.subTest(failure=type(failure).__name__):
                run.reset_mock(side_effect=True)
                sleep.reset_mock()
                run.side_effect = [failure] * 30
                self.assertFalse(WAIT.wait_running("/test/tailscale"))
                self.assertEqual(run.call_count, 30)
                self.assertEqual(sleep.call_count, 29)

    @patch.object(WAIT.time, "sleep")
    @patch.object(WAIT.subprocess, "run")
    def test_recovers_after_socket_error(self, run, sleep):
        run.side_effect = [OSError(), response('{"BackendState":"Running"}')]
        self.assertTrue(WAIT.wait_running("/test/tailscale"))
        sleep.assert_called_once_with(1)


if __name__ == "__main__":
    unittest.main()
