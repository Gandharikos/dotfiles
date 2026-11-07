import copy
import importlib.util
import json
import stat
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

try:
    import yaml
except ImportError:
    raise unittest.SkipTest("sing-box subscription tests require PyYAML") from None

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "subscription", ROOT / "scripts/sing-box-subscription.py"
)
subscription = importlib.util.module_from_spec(spec)
spec.loader.exec_module(subscription)


class SubscriptionTests(unittest.TestCase):
    def setUp(self):
        self.base = json.loads((ROOT / "config/sing-box/ymir.json").read_text())
        self.node = {
            "name": "test-node",
            "type": "trojan",
            "server": "example.com",
            "port": 443,
            "password": "test-password",
            "sni": "example.com",
            "skip-cert-verify": False,
            "udp": True,
        }

    def payload(self, nodes=None):
        return yaml.safe_dump({"proxies": [self.node] if nodes is None else nodes})

    def test_cn_rule_set_paths(self):
        rules = {rule["tag"]: rule for rule in self.base["route"]["rule_set"]}
        root = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo"
        self.assertEqual(rules["cn-domain"]["url"], f"{root}/geosite/cn.srs")
        self.assertEqual(rules["cn-ip"]["url"], f"{root}/geoip/cn.srs")

    def test_trojan_tls_and_groups(self):
        original = copy.deepcopy(self.base)
        result = subscription.make_config(self.base, self.payload(), "test-secret\n")
        node = result["outbounds"][-1]
        self.assertEqual(
            node["tls"],
            {"enabled": True, "insecure": False, "server_name": "example.com"},
        )
        self.assertEqual(node["password"], "test-password")
        self.assertEqual(node["domain_resolver"], "bootstrap")
        self.assertEqual(result["outbounds"][0]["outbounds"], ["Auto", "test-node"])
        self.assertEqual(result["outbounds"][1]["outbounds"], ["test-node"])
        self.assertEqual(result["experimental"]["clash_api"]["secret"], "test-secret")
        self.assertEqual(self.base, original)

    def test_explicit_transport_options(self):
        self.node.update(udp=False, tfo=True, alpn=["h2"], **{"skip-cert-verify": True})
        node = subscription.convert_nodes(self.payload(), set())[0]
        self.assertEqual(node["network"], "tcp")
        self.assertTrue(node["tcp_fast_open"])
        self.assertTrue(node["tls"]["insecure"])
        self.assertEqual(node["tls"]["alpn"], ["h2"])

    def test_fail_closed_on_invalid_or_unsupported_nodes(self):
        cases = [
            {"type": "ss"},
            {"network": "ws"},
            {"port": 0},
            {"port": True},
            {"password": ""},
            {"sni": 42},
            {"skip-cert-verify": "false"},
            {"udp": "true"},
            {"alpn": "h2"},
            {"name": "Tailnet"},
        ]
        for change in cases:
            with self.subTest(change=change):
                node = dict(self.node, **change)
                with self.assertRaises(subscription.ConfigError):
                    subscription.make_config(self.base, self.payload([node]), "secret")
        for nodes in ([], [self.node, self.node]):
            with self.assertRaises(subscription.ConfigError):
                subscription.make_config(self.base, self.payload(nodes), "secret")
        with self.assertRaises(subscription.ConfigError):
            subscription.make_config(self.base, self.payload(), "")

    def test_download_bypasses_tun_and_fakeip_without_url_in_argv(self):
        url = "https://example.invalid/private-token"
        routes = [{"dev": "wlan0", "metric": 600}, {"dev": "tailscale0", "metric": 1}]
        with (
            patch.object(
                subscription.subprocess,
                "check_output",
                return_value=json.dumps(routes).encode(),
            ),
            patch.object(subscription.subprocess, "run") as run,
        ):
            run.return_value.returncode = 0
            run.return_value.stdout = self.payload().encode()
            self.assertEqual(subscription.download_direct(url), self.payload())
            args = run.call_args.args[0]
            self.assertEqual(args[args.index("--interface") + 1], "wlan0")
            self.assertIn("--doh-url", args)
            self.assertIn("dns.alidns.com:443:223.5.5.5", args)
            self.assertNotIn(url, args)
            self.assertIn(url.encode(), run.call_args.kwargs["input"])

    def test_atomic_private_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "config.json"
            path.write_text("old")
            subscription.atomic_write(path, "new")
            self.assertEqual(path.read_text(), "new")
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
            self.assertEqual(list(Path(tmp).glob(".subscription-*")), [])

    def test_generation_updates_and_failure_preservation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            credentials = root / "credentials"
            credentials.mkdir()
            (credentials / "nodes.yaml").write_text(self.payload())
            (credentials / "controller-secret").write_text("test-secret")
            (credentials / "subscription-url").write_text(
                "https://example.invalid/subscription"
            )
            base = root / "base.json"
            base.write_text(json.dumps(self.base))
            state = root / "state"
            output = root / "runtime.json"

            def run(action):
                argv = [
                    "script",
                    action,
                    "--base",
                    str(base),
                    "--state",
                    str(state),
                    "--credentials",
                    str(credentials),
                    "--output",
                    str(output),
                    "--core",
                    "/unused",
                ]
                with (
                    patch("sys.argv", argv),
                    patch.object(subscription, "check_config"),
                ):
                    subscription.main()

            run("generate")
            initial_output = output.read_text()
            online = self.payload([dict(self.node, name="online-node")])
            with patch.object(subscription, "download_direct", return_value=online):
                run("update")
            self.assertEqual(output.read_text(), initial_output)
            run("generate")
            self.assertIn("online-node", output.read_text())
            cache_before = (state / "subscription.yaml").read_text()
            output_before = output.read_text()
            with (
                patch.object(
                    subscription, "download_direct", return_value=self.payload([])
                ),
                self.assertRaises(subscription.ConfigError),
            ):
                run("update")
            with (
                patch.object(
                    subscription,
                    "download_direct",
                    side_effect=subscription.ConfigError("failed"),
                ),
                self.assertRaises(subscription.ConfigError),
            ):
                run("update")
            self.assertEqual((state / "subscription.yaml").read_text(), cache_before)
            self.assertEqual(output.read_text(), output_before)
            (credentials / "nodes.yaml").write_text(
                self.payload([dict(self.node, name="rotated-node")])
            )
            run("generate")
            self.assertIn("rotated-node", output.read_text())


if __name__ == "__main__":
    unittest.main()
