import copy
import importlib.util
import json
import os
import re
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

try:
    import yaml
except ImportError:
    raise unittest.SkipTest("sing-box subscription tests require PyYAML") from None

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "subscription", ROOT / "scripts/sing-box-subscription.py"
)
subscription = importlib.util.module_from_spec(spec)
spec.loader.exec_module(subscription)


class SubscriptionTests(unittest.TestCase):
    def setUp(self):
        self.base = json.loads(
            (ROOT / "config/sing-box/config.json")
            .read_text()
            .replace("__TAILNET_DOMAIN__", "fixture.ts.net")
            .replace("__TAILNET_HOSTNAME__", "fixture-singbox")
            .replace("__SYSTEM_TAILSCALE_INTERFACE__", "tailscale0")
        )
        self.policy_path = ROOT / "config/sing-box/policy.yml"
        self.policy = subscription.load_policy(self.policy_path)
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

        self.converter_patch = patch.object(
            subscription, "run_converter", side_effect=self.converter_fixture
        )
        self.converter_patch.start()
        self.addCleanup(self.converter_patch.stop)

    @staticmethod
    def converter_fixture(nodes, _converter):
        # Node-only upstream output intentionally omits UDP/TFO, like the pinned real converter.
        result = []
        for source in nodes:
            node = {
                "tag": source["name"],
                "type": source["type"],
                "server": source["server"],
                "server_port": source["port"],
                "password": source["password"],
                "tls": {
                    "enabled": True,
                    "insecure": source.get("skip-cert-verify", False),
                },
            }
            if "sni" in source:
                node["tls"]["server_name"] = source["sni"]
            if source.get("alpn"):
                node["tls"]["alpn"] = source["alpn"]
            result.append(node)
        return result

    def payload(self, nodes=None):
        return yaml.safe_dump({"proxies": [self.node] if nodes is None else nodes})

    def test_policy_loader_accepts_yaml_and_legacy_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "policy"
            for text in (yaml.safe_dump(self.policy), json.dumps(self.policy)):
                path.write_text(text)
                self.assertEqual(subscription.load_policy(path), self.policy)

    def test_policy_loader_rejects_empty_invalid_and_unsafe_input(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "policy.yml"
            for text in (
                "",
                "[]",
                "groups: []",
                "groups: [private-policy-content",
                "!!python/object/apply:os.system [private-policy-content]",
            ):
                path.write_text(text)
                with self.assertRaises(subscription.ConfigError) as error:
                    subscription.load_policy(path)
                self.assertNotIn("private-policy-content", str(error.exception))

    def test_shared_templates_keep_host_values_as_parameters(self):
        native = json.loads((ROOT / "config/sing-box/config.json").read_text())
        self.assertEqual(native["endpoints"][0]["hostname"], "__TAILNET_HOSTNAME__")
        self.assertIn("__TAILNET_DOMAIN__", json.dumps(native["dns"]["rules"]))
        mihomo = yaml.safe_load((ROOT / "config/mihomo/config.yaml").read_text())
        self.assertEqual(mihomo["proxies"][0]["hostname"], "__TAILNET_HOSTNAME__")
        self.assertEqual(mihomo["mixed-port"], "__MIXED_PORT__")
        self.assertIn("Subscription", mihomo["proxy-providers"])
        for path in ("config/sing-box/config.json", "config/mihomo/config.yaml"):
            self.assertNotIn("ymir", (ROOT / path).read_text())
            self.assertNotIn("tail2cfd9e.ts.net", (ROOT / path).read_text())

    def test_native_tailnet_bypasses_tun_but_explicit_proxy_keeps_endpoint(self):
        tun = next(inbound for inbound in self.base["inbounds"] if inbound["type"] == "tun")
        networks = {"100.64.0.0/10", "fd7a:115c:a1e0::/48"}
        self.assertTrue(networks.issubset(tun["route_exclude_address"]))
        self.assertEqual(tun["iproute2_rule_index"], 9000)
        routes = self.base["route"]["rules"]
        self.assertTrue(any(
            networks.issubset(rule.get("ip_cidr", [])) and rule.get("outbound") == "Tailnet"
            for rule in routes
        ))
        endpoint = next(endpoint for endpoint in self.base["endpoints"] if endpoint["tag"] == "Tailnet")
        self.assertEqual(endpoint["hostname"], "fixture-singbox")

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

    def test_hong_kong_label_detection(self):
        for name in (
            "🇭🇰 node",
            "香港 01",
            "HK01",
            "hk-02",
            "HKG 03",
            "Hong Kong",
            "Hong-Kong",
            "Hong_Kong",
            "Hong.Kong",
            "HongKong",
            "ＨＫ 04",
            "🇭🇰 套餐到期日期",
        ):
            with self.subTest(name=name):
                self.assertTrue(subscription.is_hong_kong(name))
        for name in ("🇯🇵 日本", "台湾 01", "Singapore", "US 01", "THK-node", "HKBN"):
            with self.subTest(name=name):
                self.assertFalse(subscription.is_hong_kong(name))

    def test_auto_excludes_hong_kong_without_removing_manual_nodes(self):
        names = ["🇭🇰 香港 01", "HK02", "🇯🇵 日本 01", "🇺🇸 美国 01"]
        nodes = [dict(self.node, name=name) for name in names]
        result = subscription.make_config(self.base, self.payload(nodes), "secret")
        groups = {item["tag"]: item for item in result["outbounds"]}
        self.assertEqual(groups["Auto"]["outbounds"], names[2:])
        self.assertEqual(groups["Proxy"]["outbounds"], ["Auto", *names])
        self.assertEqual(
            [item["tag"] for item in result["outbounds"] if item["type"] == "trojan"],
            names,
        )
        for tag in subscription.AI_GROUPS:
            self.assertEqual(groups[tag]["outbounds"], ["Proxy", "Auto", *names])
            self.assertEqual(groups[tag]["default"], "Proxy")
            self.assertNotIn(tag, groups["Proxy"]["outbounds"])

    def test_hong_kong_only_subscription_is_rejected(self):
        with self.assertRaisesRegex(subscription.ConfigError, "non-Hong-Kong"):
            subscription.make_config(
                self.base, self.payload([dict(self.node, name="香港 01")]), "secret"
            )

    def test_ai_rules_and_dns_precede_domestic_fallback(self):
        sets = {rule["tag"]: rule for rule in self.base["route"]["rule_set"]}
        tags = ["ai-chatgpt", "ai-claude", "ai-gemini", "ai-copilot"]
        rules = self.base["route"]["rules"]
        ai_indices = []
        for tag, group in zip(tags, subscription.AI_GROUPS, strict=True):
            self.assertEqual(sets[tag]["type"], "inline")
            for condition in sets[tag]["rules"]:
                self.assertEqual(len(condition), 1)
                self.assertTrue(
                    set(condition) <= {"domain", "domain_suffix", "domain_keyword"}
                )
            ai_indices.append(rules.index({"rule_set": [tag], "outbound": group}))
        self.assertEqual(ai_indices, sorted(ai_indices))
        self.assertLess(
            rules.index({"clash_mode": "Global", "outbound": "Proxy"}), ai_indices[0]
        )
        self.assertLess(
            ai_indices[-1],
            rules.index({"rule_set": ["cn-domain", "cn-ip"], "outbound": "direct"}),
        )
        dns = self.base["dns"]["rules"]
        ai_dns = dns.index(
            {
                "rule_set": [*tags, "ai-gemini-platform"],
                "query_type": ["A", "AAAA"],
                "server": "fakeip",
            }
        )
        self.assertLess(
            dns.index({"clash_mode": "Direct", "server": "localdns"}), ai_dns
        )
        self.assertLess(
            ai_dns, dns.index({"rule_set": ["cn-domain"], "server": "localdns"})
        )

    def test_clash_ai_domain_coverage(self):
        sets = {rule["tag"]: rule for rule in self.base["route"]["rule_set"]}
        expected = {
            "ai-chatgpt": ("domain_suffix", "openai.com"),
            "ai-claude": ("domain_suffix", "anthropic.com"),
            "ai-gemini": ("domain_keyword", "generativelanguage"),
            "ai-gemini-platform": ("domain_suffix", "googleapis.com"),
            "ai-copilot": ("domain", "copilot.microsoft.com"),
        }
        for tag, (field, domain) in expected.items():
            self.assertTrue(
                any(domain in rule.get(field, []) for rule in sets[tag]["rules"])
            )

    @unittest.skipUnless(
        os.environ.get("SING_BOX"), "Set SING_BOX to test the real core"
    )
    def test_ai_rule_sets_with_real_core(self):
        sets = {rule["tag"]: rule for rule in self.base["route"]["rule_set"]}
        examples = {
            "ai-chatgpt": (
                "api.openai.com",
                "chatgpt.com",
                "chat.openai.com.cdn.cloudflare.net",
            ),
            "ai-claude": ("api.anthropic.com", "claude.ai", "claude.com"),
            "ai-gemini": (
                "gemini.google.com",
                "generativelanguage.googleapis.com",
                "ai.google.dev",
            ),
            "ai-copilot": ("copilot.microsoft.com", "www.bing.com", "sydney.bing.com"),
        }
        for tag, domains in examples.items():
            payload = json.dumps({"version": 3, "rules": sets[tag]["rules"]})
            for domain in (*domains, "example.invalid"):
                with self.subTest(tag=tag, domain=domain):
                    result = subprocess.run(
                        [
                            os.environ["SING_BOX"],
                            "--disable-color",
                            "rule-set",
                            "match",
                            "/dev/stdin",
                            domain,
                        ],
                        input=payload,
                        text=True,
                        capture_output=True,
                        check=True,
                        timeout=10,
                    )
                    self.assertEqual(
                        "match rules." in result.stderr, domain != "example.invalid"
                    )

    def test_service_selectors_keep_defaults_and_have_no_cycles(self):
        before = copy.deepcopy(self.policy)
        config = subscription.make_config(
            self.base, self.payload(), "secret", self.policy
        )
        groups = {entry["tag"]: entry for entry in config["outbounds"]}
        self.assertEqual(len(self.policy["groups"]), 20)
        self.assertNotIn("🛑 广告拦截", groups)
        self.assertNotIn("🍃 应用净化", groups)
        cloudflare = groups["☁️ CloudFlare"]
        self.assertEqual(cloudflare["default"], "Proxy")
        for tag in subscription.AI_GROUPS:
            self.assertIn(tag, cloudflare["outbounds"])
            self.assertNotIn("☁️ CloudFlare", groups[tag]["outbounds"])
        self.assertEqual(groups["🍎 苹果服务"]["default"], "direct")
        self.assertEqual(groups["📹 油管视频"]["default"], "Proxy")
        for declared in self.policy["groups"]:
            actual = groups[declared["tag"]]
            self.assertEqual(actual["outbounds"], [*declared["outbounds"], "test-node"])
            self.assertIn(actual["default"], actual["outbounds"])

        def walk(tag, parents):
            self.assertNotIn(tag, parents)
            self.assertIn(tag, groups)
            for child in groups[tag].get("outbounds", []):
                walk(child, {*parents, tag})

        for tag in groups:
            walk(tag, set())
        self.assertEqual(self.policy, before)
        with self.assertRaises(subscription.ConfigError):
            subscription.make_config(
                self.base,
                self.payload([dict(self.node, name="☁️ CloudFlare")]),
                "secret",
                self.policy,
            )

    def test_shared_cloudflare_domains_are_not_owned_by_ai_groups(self):
        sets = {entry["tag"]: entry for entry in self.base["route"]["rule_set"]}
        for tag in ("ai-chatgpt", "ai-copilot"):
            for rule in sets[tag]["rules"]:
                for values in rule.values():
                    self.assertNotIn("challenges.cloudflare.com", values)
                    self.assertNotIn("static.cloudflareinsights.com", values)
        policy_sets = {entry["tag"]: entry for entry in self.policy["rule_sets"]}
        suffixes = [
            value
            for rule in policy_sets["service-cloudflare"]["rules"]
            for value in rule.get("domain_suffix", [])
        ]
        self.assertIn("cloudflare.com", suffixes)
        self.assertIn("cloudflareinsights.com", suffixes)

    def test_service_rule_precedence_and_dns(self):
        config = subscription.apply_service_policy(self.base, self.policy)
        rules = config["route"]["rules"]
        ai = rules.index({"rule_set": ["ai-copilot"], "outbound": "🤖 Copilot"})
        cloudflare = rules.index(
            {"rule_set": ["service-cloudflare"], "outbound": "☁️ CloudFlare"}
        )
        youtube = rules.index(
            {"rule_set": ["service-youtube"], "outbound": "📹 油管视频"}
        )
        google = rules.index(
            {"rule_set": ["ai-gemini-platform"], "outbound": "🤖 Gemini"}
        )
        cn = rules.index({"rule_set": ["cn-domain", "cn-ip"], "outbound": "direct"})
        self.assertLess(ai, cloudflare)
        self.assertLess(youtube, google)
        for rule in self.policy["ip_rules"]:
            self.assertLess(google, rules.index(rule))
            self.assertLess(rules.index(rule), cn)
        dns = config["dns"]["rules"]
        service_dns = {
            "rule_set": [entry["tag"] for entry in self.policy["rule_sets"]],
            "query_type": ["A", "AAAA"],
            "server": "fakeip",
        }
        self.assertLess(
            dns.index(service_dns),
            dns.index({"rule_set": ["cn-domain"], "server": "localdns"}),
        )
        for entry in self.policy["rule_sets"]:
            self.assertEqual(entry["type"], "inline")
            self.assertTrue(
                all(
                    set(rule) <= {"domain", "domain_suffix", "domain_keyword"}
                    for rule in entry["rules"]
                )
            )

    @unittest.skipUnless(
        os.environ.get("SING_BOX"), "Set SING_BOX to test the real core"
    )
    def test_service_domain_and_ip_routing_with_real_core(self):
        config = subscription.apply_service_policy(self.base, self.policy)
        sets = {
            entry["tag"]: entry
            for entry in config["route"]["rule_set"]
            if entry["type"] == "inline"
        }
        conditions = []
        targets = []
        for rule in config["route"]["rules"]:
            if "rule_set" in rule:
                headless = [
                    condition
                    for tag in rule["rule_set"]
                    if tag in sets
                    for condition in sets[tag]["rules"]
                ]
                if not headless:
                    continue
                conditions.append({"type": "logical", "mode": "or", "rules": headless})
            elif "ip_cidr" in rule:
                conditions.append({"ip_cidr": rule["ip_cidr"]})
            else:
                continue
            targets.append(rule["outbound"])
        payload = json.dumps({"version": 3, "rules": conditions})
        examples = {
            "api.openai.com": "🤖 ChatGPT",
            "chat.openai.com.cdn.cloudflare.net": "🤖 ChatGPT",
            "api.anthropic.com": "🤖 Claude",
            "copilot.microsoft.com": "🤖 Copilot",
            "generativelanguage.googleapis.com": "🤖 Gemini",
            "challenges.cloudflare.com": "☁️ CloudFlare",
            "static.cloudflareinsights.com": "☁️ CloudFlare",
            "104.16.0.1": "☁️ CloudFlare",
            "2606:4700::1": "☁️ CloudFlare",
            "youtubei.googleapis.com": "📹 油管视频",
            "www.youtube.com": "📹 油管视频",
            "mtalk.google.com": "📢 谷歌FCM",
            "www.google.com": "🤖 Gemini",
            "www.netflix.com": "🎥 奈飞视频",
            "api.telegram.org": "📲 电报消息",
            "store.steampowered.com": "🎮 Steam网页",
            "steampipe.steamcontent.com": "🎮 Steam下载",
            "www.epicgames.com": "🎮 游戏平台",
            "www.disneyplus.com": "🎥 迪士尼+",
            "www.gamer.com.tw": "📺 巴哈姆特",
            "www.bilibili.com": "📺 哔哩哔哩",
            "www.onedrive.com": "Ⓜ️ 微软云盘",
            "www.microsoft.com": "Ⓜ️ 微软服务",
            "www.apple.com": "🍎 苹果服务",
            "music.163.com": "🎶 网易音乐",
            "www.tiktok.com": "📹 TikTok",
            "www.hbomax.com": "📺 HBO系列",
            "www.primevideo.com": "🎥 亚马逊视频",
            "www.hulu.com": "📺 Hulu",
            "www.dazn.com": "📹 DAZN",
            "d151l6v8er5bdm.cloudfront.net": "📹 DAZN",
            "example.invalid": "Proxy",
        }
        for address, expected in examples.items():
            with self.subTest(address=address):
                result = subprocess.run(
                    [
                        os.environ["SING_BOX"],
                        "--disable-color",
                        "rule-set",
                        "match",
                        "/dev/stdin",
                        address,
                    ],
                    input=payload,
                    text=True,
                    capture_output=True,
                    check=True,
                    timeout=10,
                )
                matches = [
                    int(index)
                    for index in re.findall(r"match rules\.\[(\d+)\]", result.stderr)
                ]
                actual = targets[min(matches)] if matches else "Proxy"
                self.assertEqual(actual, expected)

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
            *({"name": name} for name in subscription.AI_GROUPS),
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

    def test_converter_rejects_dropped_renamed_or_changed_nodes(self):
        valid = self.converter_fixture([self.node], None)
        cases = [[], {}, valid + valid]
        for field, value in (
            ("tag", "renamed"),
            ("password", "changed"),
            ("type", "direct"),
            ("server_port", True),
            ("detour", "direct"),
            ("tls", {}),
        ):
            changed = copy.deepcopy(valid)
            changed[0][field] = value
            cases.append(changed)
        changed = copy.deepcopy(valid)
        changed[0]["tls"]["insecure"] = True
        cases.append(changed)
        for result in cases:
            with (
                self.subTest(result=result),
                patch.object(subscription, "run_converter", return_value=result),
                self.assertRaises(subscription.ConfigError),
            ):
                subscription.convert_nodes(self.payload(), set())

    def test_converter_keeps_credentials_off_argv_and_cleans_private_files(self):
        self.converter_patch.stop()
        paths = []

        def run(args, **kwargs):
            self.assertNotIn(self.node["password"], " ".join(args))
            settings = json.loads(json.loads(args[-1]))
            source = Path(settings["subscribes"][0]["url"])
            output = Path(settings["save_config_path"])
            paths.extend([source, output, source.parent])
            self.assertTrue(settings["Only-nodes"])
            self.assertEqual(stat.S_IMODE(source.stat().st_mode), 0o600)
            self.assertEqual(stat.S_IMODE(source.parent.stat().st_mode), 0o700)
            self.assertEqual(kwargs["umask"], 0o077)
            self.assertTrue(kwargs["capture_output"])
            self.assertEqual(yaml.safe_load(source.read_text())["proxies"], [self.node])
            output.write_text(json.dumps(self.converter_fixture([self.node], None)))
            return subprocess.CompletedProcess(args, 0, b"", b"")

        with patch.object(subscription.subprocess, "run", side_effect=run):
            self.assertEqual(
                subscription.run_converter([self.node], "/converter")[0]["tag"],
                self.node["name"],
            )
        self.assertTrue(all(not path.exists() for path in paths))

    def test_converter_failure_diagnostics_are_not_exposed(self):
        self.converter_patch.stop()
        with (
            patch.object(
                subscription.subprocess,
                "run",
                return_value=subprocess.CompletedProcess([], 1, b"private", b"private"),
            ),
            self.assertRaises(subscription.ConfigError) as error,
        ):
            subscription.run_converter([self.node], "/converter")
        self.assertNotIn("private", str(error.exception))

    @unittest.skipUnless(
        os.environ.get("SUB2SINGBOX"), "set SUB2SINGBOX to test the packaged converter"
    )
    def test_real_converter_preserves_trojan_settings(self):
        self.converter_patch.stop()
        for password in ("test-password", "p@ss:/?#%&+字", "literal%2Fvalue"):
            for alpn in ([], ["h2", "http/1.1"]):
                with self.subTest(password=password, alpn=alpn):
                    node = dict(
                        self.node,
                        name="🇯🇵 日本 / test",
                        password=password,
                        alpn=alpn,
                        udp=False,
                        tfo=True,
                    )
                    converted = subscription.convert_nodes(self.payload([node]), set())[
                        0
                    ]
                    self.assertEqual(converted["tag"], node["name"])
                    self.assertEqual(converted["password"], password)
                    self.assertEqual(converted["tls"]["alpn"], alpn)
                    self.assertFalse(converted["tls"]["insecure"])
                    self.assertEqual(converted["network"], "tcp")
                    self.assertTrue(converted["tcp_fast_open"])

        with self.subTest(case="IPv6 without explicit SNI"):
            node = dict(
                self.node, server="2001:db8::1", tfo=False, **{"skip-cert-verify": True}
            )
            del node["sni"]
            converted = subscription.convert_nodes(self.payload([node]), set())[0]
            self.assertEqual(converted["server"], node["server"])
            self.assertEqual(converted["tls"], {"enabled": True, "insecure": True})
            self.assertFalse(converted["tcp_fast_open"])
            self.assertNotIn("network", converted)

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

            def run(action, policy_path=None):
                argv = [
                    "script",
                    action,
                    "--base",
                    str(base),
                    "--policy",
                    str(policy_path if policy_path is not None else self.policy_path),
                    "--state",
                    str(state),
                    "--credentials",
                    str(credentials),
                    "--output",
                    str(output),
                    "--core",
                    "/unused",
                    "--converter",
                    "/unused-converter",
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
                    return_value=self.payload([dict(self.node, name="🇭🇰 香港")]),
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
            with (
                patch.object(
                    subscription,
                    "run_converter",
                    side_effect=subscription.ConfigError("converter failed"),
                ),
                self.assertRaises(subscription.ConfigError),
            ):
                run("generate")
            invalid_policy = root / "invalid-policy.yml"
            for text in ("", "[]"):
                invalid_policy.write_text(text)
                with self.assertRaises(subscription.ConfigError):
                    run("generate", invalid_policy)
            self.assertEqual((state / "subscription.yaml").read_text(), cache_before)
            self.assertEqual(output.read_text(), output_before)
            (credentials / "nodes.yaml").write_text(
                self.payload([dict(self.node, name="rotated-node")])
            )
            run("generate")
            self.assertIn("rotated-node", output.read_text())


if __name__ == "__main__":
    unittest.main()
