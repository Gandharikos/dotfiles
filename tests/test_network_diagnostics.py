import importlib.util
import json
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch

PATH = Path(__file__).resolve().parents[1] / "scripts/network-diagnostics.py"
spec = importlib.util.spec_from_file_location("network_diagnostics", PATH)
diagnostics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diagnostics)
PRIVATE = "DO-NOT-PRINT-CREDENTIAL-CONTENT"


class DiagnosticsTests(unittest.TestCase):
    def setUp(self):
        self.commands = []

    def execute(self, command, **kwargs):
        self.commands.append(command)
        self.assertNotIn("shell", kwargs)
        self.assertEqual(kwargs["timeout"], 5)
        self.assertEqual(kwargs["stdin"], subprocess.DEVNULL)
        tool = command[0]
        if tool == "systemctl":
            self.assertEqual(
                command[1:-1],
                (["--user"] if command[1] == "--user" else [])
                + [
                    "show",
                    "--no-pager",
                    "--property=" + ",".join(diagnostics.SERVICE_PROPERTIES),
                ],
            )
            self.assertIn(
                command[-1],
                [f"{name}.service" for name in diagnostics.SERVICES] + ["rex.service"],
            )
            text = f"LoadState=loaded\nActiveState=active\nSubState=running\nMainPID=42\nNRestarts=0\nEnvironment={PRIVATE}"
        elif tool == "git":
            self.assertEqual(
                command[1:], ["-C", str(PATH.parents[1]), "rev-parse", "HEAD"]
            )
            text = "a" * 40
        elif tool == "ip":
            allowed = [
                ["-j", "link", "show"],
                ["-j", "nexthop", "show"],
                *[["-j", family, "rule", "show"] for family in ("-4", "-6")],
                *[
                    ["-j", family, "route", "show", "table", "all"]
                    for family in ("-4", "-6")
                ],
            ]
            self.assertIn(command[1:], allowed)
            if "link" in command:
                rows = [
                    {
                        "ifname": "sb-tun",
                        "mtu": 1500,
                        "operstate": "UNKNOWN",
                        "address": PRIVATE,
                    }
                ]
            elif "rule" in command:
                rows = [{"priority": 5260, "table": 52, "src": PRIVATE, "dst": "all"}]
            elif "route" in command:
                rows = [
                    {
                        "table": 2022,
                        "dev": "sb-tun",
                        "dst": "default",
                        "gateway": PRIVATE,
                    },
                    {"table": 2022, "dev": "sb-tun", "dst": PRIVATE},
                ]
            else:
                rows = [{"id": 1, "dev": "wlan0", "gateway": PRIVATE}]
            text = json.dumps(rows)
        elif tool == "tc":
            self.assertEqual(command[1:], ["-j", "qdisc", "show"])
            text = json.dumps(
                [
                    {
                        "dev": "wlan0",
                        "kind": "fq",
                        "root": True,
                        "options": {"private": PRIVATE},
                    }
                ]
            )
        elif tool == "networkctl":
            self.assertEqual(command[1:], ["--json=short", "list", "--no-pager"])
            text = json.dumps(
                {
                    "Interfaces": [
                        {
                            "Name": "sb-tun",
                            "AdministrativeState": "unmanaged",
                            "Addresses": [PRIVATE],
                        }
                    ],
                    "Secret": PRIVATE,
                }
            )
        elif tool == "nmcli":
            self.assertEqual(
                command[1:], ["-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
            )
            text = "wlan0:wifi:connected\nvirbr0:bridge:connected (externally)\nsb-tun:tun:unmanaged"
        elif tool == "resolvectl":
            self.assertEqual(command[1:], ["--json=short", "status"])
            text = json.dumps(
                [
                    {
                        "servers": [
                            {
                                "addressString": "127.0.0.1",
                                "port": 1053,
                                "secret": PRIVATE,
                            }
                        ],
                        "searchDomains": [{"name": ".", "routeOnly": True}],
                        "other": PRIVATE,
                    }
                ]
            )
        elif tool == "sysctl":
            self.assertEqual(command[1:], ["-e", *diagnostics.SYSCTLS])
            text = f"net.core.default_qdisc = fq\nunknown.secret = {PRIVATE}"
        else:
            self.fail(f"Unexpected command: {tool}")
        return subprocess.CompletedProcess(command, 0, text, PRIVATE)

    def collect(self, execute=None):
        with (
            patch.object(
                diagnostics.subprocess, "run", side_effect=execute or self.execute
            ),
            patch.object(
                diagnostics.os, "readlink", return_value="/nix/store/test-system"
            ),
        ):
            return diagnostics.collect()

    def test_only_fixed_read_queries_and_selected_fields(self):
        report = self.collect()
        self.assertNotIn(PRIVATE, json.dumps(report))
        self.assertEqual(report["errors"], [])
        self.assertEqual(report["services"]["sing-box"]["MainPID"], "42")
        self.assertEqual(report["networkd"][0]["AdministrativeState"], "unmanaged")
        self.assertEqual(
            report["network_manager"][1]["state"], "connected (externally)"
        )
        self.assertEqual(
            report["resolved"][0]["servers"],
            [{"addressString": "127.0.0.1", "port": 1053}],
        )
        self.assertEqual(report["routing"]["ipv4"]["routes"][0]["routes"], 2)
        self.assertEqual(report["routing"]["ipv6"]["routes"][0]["default_routes"], 1)
        self.assertTrue(report["routing"]["ipv4"]["rules"][0]["source_scoped"])
        self.assertFalse(report["routing"]["ipv4"]["rules"][0]["destination_scoped"])
        self.assertEqual(report["sysctls"], {"net.core.default_qdisc": "fq"})
        self.assertIn("net.ipv4.tcp_mtu_probing", report["unavailable_sysctls"])
        self.assertEqual(
            report["qdiscs"], [{"dev": "wlan0", "kind": "fq", "root": True}]
        )
        self.assertEqual(len(self.commands), 21)

    def test_missing_tools_are_reported_without_exception_details(self):
        def missing(*args, **kwargs):
            raise FileNotFoundError(PRIVATE)

        report = self.collect(missing)
        self.assertIsNone(report["links"])
        self.assertIsNone(report["resolved"])
        self.assertTrue(report["errors"])
        self.assertNotIn(PRIVATE, json.dumps(report))

    def test_timeouts_and_failed_queries_never_echo_output(self):
        for failure in (
            subprocess.TimeoutExpired("query", 5, output=PRIVATE, stderr=PRIVATE),
            subprocess.CompletedProcess([], 1, PRIVATE, PRIVATE),
        ):

            def failed(*args, failure=failure, **kwargs):
                if isinstance(failure, Exception):
                    raise failure
                return failure

            with self.subTest(failure=type(failure).__name__):
                report = self.collect(failed)
                self.assertTrue(report["errors"])
                self.assertNotIn(PRIVATE, json.dumps(report))

    def test_invalid_json_or_schema_is_unavailable(self):
        for text in (PRIVATE, '"string"', "null", "[1]", "{}"):
            with (
                self.subTest(text=text),
                patch.object(
                    diagnostics.subprocess,
                    "run",
                    return_value=subprocess.CompletedProcess([], 0, text, PRIVATE),
                ),
            ):
                probe = diagnostics.Probe()
                self.assertIsNone(probe.rows(["ip", "-j", "link", "show"]))
                self.assertEqual(probe.errors[0]["reason"], "unsupported JSON response")
                self.assertNotIn(PRIVATE, json.dumps(probe.errors))

    def test_unknown_nested_values_are_not_exposed(self):
        self.assertEqual(
            diagnostics.select({"Name": {"secret": PRIVATE}}, ["Name"]), {}
        )
        self.assertIsNone(diagnostics.resolved_summary([{"servers": None}]))
        self.assertIsNone(diagnostics.resolved_summary([{"searchDomains": "wrong"}]))
        self.assertEqual(diagnostics.resolved_summary([]), [])
        self.assertIsNone(diagnostics.route_summary(None))
        self.assertIsNone(diagnostics.rule_summary(None))

    def test_invalid_dns_structure_is_reported(self):
        for response in ('{"ignored": true}', '[{"servers": null}]'):

            def execute(command, response=response, **kwargs):
                if command[0] == "resolvectl":
                    return subprocess.CompletedProcess(command, 0, response, "")
                return self.execute(command, **kwargs)

            report = self.collect(execute)
            self.assertIsNone(report["resolved"])
            self.assertTrue(report["errors"])

    def test_missing_generation_links_are_optional(self):
        with patch.object(
            diagnostics.os, "readlink", side_effect=FileNotFoundError(PRIVATE)
        ):
            self.assertIsNone(diagnostics.link_target("/run/current-system"))


if __name__ == "__main__":
    unittest.main()
