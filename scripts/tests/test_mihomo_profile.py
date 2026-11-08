import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]


class MihomoProfileTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base_text = (ROOT / "config/mihomo/config.yaml").read_text()
        cls.policy_text = (ROOT / "config/mihomo/policy.yaml").read_text()
        cls.base = yaml.safe_load(cls.base_text)
        cls.policy = yaml.safe_load(cls.policy_text)

    def test_fragments_form_one_mapping_without_overrides(self):
        self.assertEqual(set(self.policy), {"proxy-groups", "rule-providers", "rules"})
        self.assertFalse(set(self.base) & set(self.policy))
        documents = list(yaml.safe_load_all(self.base_text + "\n" + self.policy_text))
        self.assertEqual(documents, [self.base | self.policy])

    def test_runtime_credentials_and_provider_cache_stay_in_base(self):
        self.assertTrue(
            self.base["secret"] == "__CONTROLLER_SECRET__",
            "Expected a controller placeholder",
        )
        provider = self.base["proxy-providers"]["Subscription"]
        self.assertTrue(
            provider["url"] == "__SUBSCRIPTION_URL__",
            "Expected a subscription placeholder",
        )
        self.assertEqual(provider["path"], "./providers/wgetcloud.yaml")
        self.assertEqual(provider["proxy"], "DIRECT")
        self.assertNotIn("__CONTROLLER_SECRET__", self.policy_text)
        self.assertNotIn("__SUBSCRIPTION_URL__", self.policy_text)

    def test_groups_preserve_fail_closed_defaults(self):
        groups = {group["name"]: group for group in self.policy["proxy-groups"]}
        self.assertEqual(groups["Proxy"]["proxies"], ["Auto"])
        self.assertEqual(groups["Auto"]["proxies"], ["REJECT"])
        for group in groups.values():
            self.assertEqual(group["use"], ["Subscription"])
        self.assertEqual(self.base["proxies"][0]["dialer-proxy"], "Proxy")

    def test_native_tailnet_bypasses_tun(self):
        tun = self.base["tun"]
        self.assertTrue(
            {"100.64.0.0/10", "fd7a:115c:a1e0::/48"}.issubset(tun["route-exclude-address"])
        )
        self.assertEqual(tun["iproute2-rule-index"], 9000)

    def test_routing_precedence_and_dns_references(self):
        self.assertEqual(
            self.policy["rules"][:4],
            [
                "PROCESS-NAME,rex,DIRECT",
                "DOMAIN-SUFFIX,__TAILNET_DOMAIN__,Tailnet",
                "IP-CIDR,100.64.0.0/10,Tailnet,no-resolve",
                "IP-CIDR6,fd7a:115c:a1e0::/48,Tailnet,no-resolve",
            ],
        )
        self.assertEqual(self.policy["rules"][-1], "MATCH,Proxy")
        self.assertEqual(set(self.policy["rule-providers"]), {"cn-domain", "cn-ip"})
        self.assertIn("rule-set:cn-domain", self.base["dns"]["nameserver-policy"])
        for provider in self.policy["rule-providers"].values():
            self.assertEqual(provider["proxy"], "DIRECT")


if __name__ == "__main__":
    unittest.main()
