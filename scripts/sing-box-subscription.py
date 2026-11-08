"""Combine sub2singbox nodes with shared policy without storing credentials in Nix."""

import argparse
import copy
import fcntl
import hashlib
import json
import os
import re
import subprocess
import tempfile
import unicodedata
from pathlib import Path

import yaml


class ConfigError(ValueError):
    pass


def convert_nodes(text, reserved, converter=None):
    document = yaml.safe_load(text)
    if not isinstance(document, dict) or not isinstance(document.get("proxies"), list):
        raise ConfigError("Expected a Clash proxies list")
    nodes = document["proxies"]
    if not nodes:
        raise ConfigError("Empty subscriptions are not allowed")
    allowed = {
        "name",
        "type",
        "server",
        "port",
        "password",
        "sni",
        "skip-cert-verify",
        "udp",
        "alpn",
        "tfo",
    }
    used = set(reserved)
    for node in nodes:
        if not isinstance(node, dict) or node.get("type") != "trojan":
            raise ConfigError(
                "This profile only supports Trojan nodes; refusing a partial conversion"
            )
        if set(node) - allowed:
            raise ConfigError(
                "Unsupported Trojan options; refusing to silently discard settings"
            )
        for field in ("name", "server", "password"):
            if not isinstance(node.get(field), str) or not node[field]:
                raise ConfigError("Missing or invalid Trojan field")
        if node["name"] in used:
            raise ConfigError("Duplicate or reserved node name")
        used.add(node["name"])
        port = node.get("port")
        if type(port) is not int or not 1 <= port <= 65535:
            raise ConfigError("Invalid Trojan port")
        for field in ("skip-cert-verify", "udp", "tfo"):
            if field in node and type(node[field]) is not bool:
                raise ConfigError("Invalid Trojan boolean option")
        if "sni" in node and (not isinstance(node["sni"], str) or not node["sni"]):
            raise ConfigError("Invalid Trojan SNI")
        if "alpn" in node and (
            not isinstance(node["alpn"], list)
            or not all(isinstance(x, str) and x for x in node["alpn"])
        ):
            raise ConfigError("Invalid Trojan ALPN")

    result = run_converter(nodes, converter)
    if not isinstance(result, list) or len(result) != len(nodes):
        raise ConfigError(
            "sub2singbox dropped or added nodes; refusing a partial conversion"
        )
    fields = {
        "type": "type",
        "tag": "name",
        "server": "server",
        "server_port": "port",
        "password": "password",
    }
    for node, outbound in zip(nodes, result, strict=True):
        if not isinstance(outbound, dict) or set(outbound) - (set(fields) | {"tls"}):
            raise ConfigError("Unexpected sub2singbox outbound options")
        if any(
            type(outbound.get(key)) is not type(node[source])
            or outbound.get(key) != node[source]
            for key, source in fields.items()
        ):
            raise ConfigError("sub2singbox changed node identity or credentials")
        tls = outbound.get("tls")
        if (
            not isinstance(tls, dict)
            or set(tls) - {"enabled", "insecure", "server_name", "alpn"}
            or tls.get("enabled") is not True
            or tls.get("insecure") is not node.get("skip-cert-verify", False)
            or tls.get("server_name") != node.get("sni")
            or tls.get("alpn", []) != node.get("alpn", [])
        ):
            raise ConfigError("sub2singbox changed TLS settings")
        if "alpn" in node:
            tls["alpn"] = node["alpn"]
        # The pinned converter does not carry these Clash flags through its URI intermediate.
        outbound["domain_resolver"] = "bootstrap"
        if node.get("udp") is False:
            outbound["network"] = "tcp"
        if "tfo" in node:
            outbound["tcp_fast_open"] = node["tfo"]
    return result


def run_converter(nodes, converter):
    with tempfile.TemporaryDirectory(prefix=".sub2singbox-") as tmp:
        source = Path(tmp) / "nodes.yaml"
        output = Path(tmp) / "nodes.json"
        atomic_write(source, yaml.safe_dump({"proxies": nodes}, allow_unicode=True))
        settings = {
            "subscribes": [{"tag": "nodes", "url": str(source)}],
            "Only-nodes": True,
            "save_config_path": str(output),
        }
        try:
            result = subprocess.run(
                [
                    converter or os.environ.get("SUB2SINGBOX", "sub2singbox"),
                    "--template_index=0",
                    "--temp_json_data",
                    json.dumps(json.dumps(settings)),
                ],
                capture_output=True,
                check=False,
                timeout=30,
                umask=0o077,
            )
            if result.returncode or not output.is_file():
                raise ConfigError(
                    "sub2singbox failed; existing files were not replaced"
                )
            return json.loads(output.read_text())
        except (OSError, subprocess.SubprocessError, ValueError):
            # Never propagate converter diagnostics or JSON containing credentials.
            raise ConfigError(
                "sub2singbox failed; existing files were not replaced"
            ) from None


AI_GROUPS = ("🤖 ChatGPT", "🤖 Claude", "🤖 Gemini", "🤖 Copilot")
HONG_KONG = re.compile(
    r"🇭🇰|香港|hong[\s._-]*kong|(?<![a-z])hkg?(?![a-z])", re.IGNORECASE
)


def is_hong_kong(name):
    return HONG_KONG.search(unicodedata.normalize("NFKC", name)) is not None


def load_policy(path):
    text = path.read_text()
    try:
        # JSON's surrogate-pair escapes must be decoded before falling back to YAML.
        policy = json.loads(text)
    except json.JSONDecodeError:
        try:
            policy = yaml.safe_load(text)
        except yaml.YAMLError:
            raise ConfigError("Invalid service policy YAML") from None
    sections = ("groups", "rule_sets", "process_rules", "domain_rules", "ip_rules")
    if not isinstance(policy, dict) or any(
        not isinstance(policy.get(section), list) for section in sections
    ):
        raise ConfigError("Service policy must contain all five policy section lists")
    return policy


def apply_service_policy(base, policy):
    config = copy.deepcopy(base)
    policy = copy.deepcopy(policy)
    config["outbounds"].extend(policy["groups"])
    config["route"]["rule_set"].extend(policy["rule_sets"])
    rules = config["route"]["rules"]
    # Service-specific domains must win over Gemini's broad Google platform fallback.
    index = rules.index({"rule_set": ["ai-gemini-platform"], "outbound": "🤖 Gemini"})
    rules[index:index] = policy["process_rules"] + policy["domain_rules"]
    index = rules.index({"rule_set": ["cn-domain", "cn-ip"], "outbound": "direct"})
    rules[index:index] = policy["ip_rules"]
    dns = config["dns"]["rules"]
    index = dns.index({"rule_set": ["cn-domain"], "server": "localdns"})
    dns.insert(
        index,
        {
            "rule_set": [rule["tag"] for rule in policy["rule_sets"]],
            "query_type": ["A", "AAAA"],
            "server": "fakeip",
        },
    )
    return config


def make_config(base, text, secret, policy=None, converter=None):
    config = (
        apply_service_policy(base, policy)
        if policy is not None
        else copy.deepcopy(base)
    )
    reserved = {
        item["tag"] for item in config["outbounds"] + config.get("endpoints", [])
    }
    nodes = convert_nodes(text, reserved, converter)
    tags = [node["tag"] for node in nodes]
    auto_tags = [tag for tag in tags if not is_hong_kong(tag)]
    if not auto_tags:
        raise ConfigError("No non-Hong-Kong nodes available for Auto")
    for outbound in config["outbounds"]:
        if outbound["tag"] == "Proxy":
            outbound["outbounds"] = ["Auto", *tags]
        elif outbound["tag"] == "Auto":
            outbound["outbounds"] = auto_tags
        elif outbound["type"] == "selector":
            outbound["outbounds"] = [*outbound["outbounds"], *tags]
    config["outbounds"].extend(nodes)
    if not secret.strip():
        raise ConfigError("Missing controller secret")
    config["experimental"]["clash_api"]["secret"] = secret.strip()
    return config


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, name = tempfile.mkstemp(dir=path.parent, prefix=".subscription-")
    try:
        with os.fdopen(fd, "w") as output:
            output.write(content)
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def check_config(core, state, config):
    with tempfile.TemporaryDirectory(dir=state, prefix=".check-") as tmp:
        path = Path(tmp) / "config.json"
        atomic_write(path, json.dumps(config, ensure_ascii=False))
        result = subprocess.run(
            [core, "-D", str(state), "-c", str(path), "check"],
            capture_output=True,
            check=False,
            timeout=30,
        )
        if result.returncode:
            # Core diagnostics can contain endpoint names/credentials.
            raise ConfigError(
                "sing-box rejected the generated profile; existing files were not replaced"
            )


def download_direct(url):
    if not url.startswith("https://") or any(c in url for c in "\r\n"):
        raise ConfigError("Subscription must use HTTPS")
    routes = json.loads(
        subprocess.check_output(
            ["ip", "-j", "-4", "route", "show", "table", "main", "default"]
        )
    )
    routes = [
        r
        for r in routes
        if r.get("dev") not in (None, "tailscale0", "sb-tun", "mihomo")
    ]
    if not routes:
        raise ConfigError(
            "No physical IPv4 default route for direct subscription refresh"
        )
    interface = min(routes, key=lambda r: r.get("metric", 0))["dev"]
    result = subprocess.run(
        [
            "curl",
            "--fail",
            "--silent",
            "--show-error",
            "--location",
            "--max-redirs",
            "5",
            "--proto",
            "=https",
            "--proto-redir",
            "=https",
            "--noproxy",
            "*",
            # Bypass resolved/fake-IP as well as the proxy TUN, including redirects.
            "--interface",
            interface,
            "--doh-url",
            "https://dns.alidns.com/dns-query",
            "--resolve",
            "dns.alidns.com:443:223.5.5.5",
            "--connect-timeout",
            "10",
            "--max-time",
            "60",
            "--max-filesize",
            "2097152",
            "--user-agent",
            "ClashMeta/1.19.33",
            "--config",
            "-",
        ],
        input=f"url = {json.dumps(url)}\n".encode(),
        capture_output=True,
        check=False,
        timeout=65,
    )
    if result.returncode:
        raise ConfigError(
            "Direct subscription refresh failed; retained the previous nodes and config"
        )
    return result.stdout.decode("utf-8-sig")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("generate", "update"))
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--policy", type=Path, required=True)
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--credentials", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--core", required=True)
    parser.add_argument("--converter", required=True)
    args = parser.parse_args()
    os.umask(0o077)
    args.state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (args.state / ".subscription.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        base = json.loads(args.base.read_text())
        policy = load_policy(args.policy)
        secret = (args.credentials / "controller-secret").read_text()
        seed = (args.credentials / "nodes.yaml").read_text()
        digest = hashlib.sha256(seed.encode()).hexdigest()
        cache = args.state / "subscription.yaml"
        marker = args.state / "subscription.seed-sha256"
        if args.action == "update":
            text = download_direct(
                (args.credentials / "subscription-url").read_text().strip()
            )
        elif (
            cache.is_file()
            and marker.is_file()
            and marker.read_text().strip() == digest
        ):
            text = cache.read_text()
        else:
            text = seed
        config = make_config(base, text, secret, policy, args.converter)
        check_config(args.core, args.state, config)
        if args.action == "generate":
            atomic_write(
                args.output, json.dumps(config, indent=2, ensure_ascii=False) + "\n"
            )
        # Publish only a fully converted and core-validated subscription.
        atomic_write(cache, text)
        atomic_write(marker, digest + "\n")
        print(
            "Validated subscription updated"
            if args.action == "update"
            else "Native sing-box configuration generated"
        )


if __name__ == "__main__":
    try:
        main()
    except ConfigError as error:
        raise SystemExit(str(error)) from None
    except (
        OSError,
        yaml.YAMLError,
        subprocess.SubprocessError,
        UnicodeError,
        ValueError,
    ):
        # Never emit external YAML or the raw subprocess diagnostics to the journal.
        raise SystemExit(
            "sing-box subscription operation failed; no unvalidated configuration was installed"
        ) from None
