import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("dae_profile", ROOT / "scripts/dae-profile.py")
DAE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DAE)


def fixture():
    groups = json.loads((ROOT / "config/dae/groups.json").read_text())
    names = sorted({n for members in groups["groups"].values() for n in members} - groups["groups"].keys() - {"DIRECT", "REJECT"})
    document = {"proxies": [
        {"name": n, "type": "trojan", "server": "192.0.2.1", "port": 443,
         "password": "fixture:@ /?#", "sni": "fixture.example", "udp": True}
        for n in names
    ]}
    parameters = {"selections": {}, "wan": ["auto"], "lan": [], "dnsPort": 21053,
                  "tproxyPort": 12345, "tailnetDomain": "fixture.ts.net"}
    return groups, parameters, document


class DaeProfileTests(unittest.TestCase):
    def test_full_policy_and_saved_selections(self):
        groups, params, nodes = fixture()
        text = DAE.render((ROOT / "config/dae/config.dae").read_text(),
                          (ROOT / "config/dae/policy.dae").read_text(), groups, params, nodes)
        self.assertNotIn("__POLICY_", text)
        self.assertNotIn("__NODES__", text)
        self.assertIn("tcp+udp://127.0.0.1:21053", text)
        self.assertIn("qname(suffix:'fixture.ts.net') -> tailnet", text)
        self.assertIn("wan_interface: auto", text)
        self.assertNotIn("lan_interface:", text)
        names = [n["name"] for n in nodes["proxies"]]
        selected = names.index(groups["selections"]["🚀 节点选择"])
        self.assertIn(f"fallback: node_{selected}", text)
        self.assertNotIn("allowInsecure", text)
        self.assertIn("fixture%3A%40%20%2F%3F%23", text)

    def test_password_placeholders_are_not_interpolated(self):
        groups, params, nodes = fixture()
        nodes["proxies"][0]["password"] = "__RULES__"
        text = DAE.render((ROOT / "config/dae/config.dae").read_text(),
                          (ROOT / "config/dae/policy.dae").read_text(), groups, params, nodes)
        self.assertIn("trojan://__RULES__@", text)

    def test_order_and_process_rules(self):
        text, _ = DAE.compile_rules([
            "DOMAIN-SUFFIX,example.com,REJECT", "DOMAIN,ok.example.com,DIRECT",
            "PROCESS-NAME,client.exe,DIRECT", "IP-CIDR,192.0.2.0/24,DIRECT,no-resolve",
            "MATCH,DIRECT",
        ], [])
        self.assertLess(text.index("suffix:"), text.index("full:"))
        self.assertIn("pname('client.exe') -> direct", text)
        self.assertIn("dip('192.0.2.0/24') -> direct", text)
        self.assertTrue(text.endswith("fallback: direct"))
        for bad in (["RULE-SET,remote,DIRECT", "MATCH,DIRECT"], ["MATCH,DIRECT", "DOMAIN,x,DIRECT"]):
            with self.assertRaises(ValueError):
                DAE.compile_rules(bad, [])

    def test_tls_and_unsupported_node_options(self):
        _, _, document = fixture()
        document["proxies"] = document["proxies"][:1]
        document["proxies"][0]["skip-cert-verify"] = True
        self.assertIn("allowInsecure=1", DAE.render_nodes(document)[1])
        for key, value in (("udp", False), ("network", "ws"), ("alpn", ["h2"])):
            copy = json.loads(json.dumps(document))
            copy["proxies"][0][key] = value
            with self.assertRaises(ValueError):
                DAE.render_nodes(copy)

    def test_missing_nodes_and_invalid_choices_fail(self):
        groups, params, nodes = fixture()
        for choice in ("missing", "REJECT"):
            params["selections"] = {"🚀 节点选择": choice}
            with self.assertRaises(ValueError):
                DAE.render("__RULES__", "", groups, params, nodes)
        params["selections"] = {}
        nodes["proxies"].pop()
        with self.assertRaises(ValueError):
            DAE.render("__RULES__", "", groups, params, nodes)

    def test_validation_failure_is_private_and_atomic(self):
        groups, params, nodes = fixture()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            (path / "parameters.json").write_text(json.dumps(params))
            (path / "nodes.json").write_text(json.dumps(nodes))
            (path / "config.dae").write_text("previous valid config")
            core = path / "dae"
            core.write_text("#!/bin/sh\necho 'fixture:@ /?#' >&2\nexit 1\n")
            core.chmod(0o700)
            result = subprocess.run([
                sys.executable, str(ROOT / "scripts/dae-profile.py"),
                "--template", str(ROOT / "config/dae/config.dae"),
                "--policy", str(ROOT / "config/dae/policy.dae"),
                "--groups", str(ROOT / "config/dae/groups.json"),
                "--parameters", str(path / "parameters.json"),
                "--nodes", str(path / "nodes.json"), "--output", str(path / "config.dae"),
                "--core", str(core),
            ], capture_output=True, text=True, env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"})
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("fixture:@", result.stdout + result.stderr)
            self.assertEqual((path / "config.dae").read_text(), "previous valid config")
            self.assertEqual(list(path.glob(".config-*")), [])


if __name__ == "__main__":
    unittest.main()
