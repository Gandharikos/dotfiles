"""Build ymir's native sing-box profile without putting credentials in the store."""

import argparse
import copy
import fcntl
import hashlib
import json
import os
import subprocess
import tempfile
from pathlib import Path

import yaml


class ConfigError(ValueError):
    pass


def convert_nodes(text, reserved):
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
    result = []
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
        tls = {"enabled": True, "insecure": node.get("skip-cert-verify", False)}
        if "sni" in node:
            if not isinstance(node["sni"], str) or not node["sni"]:
                raise ConfigError("Invalid Trojan SNI")
            tls["server_name"] = node["sni"]
        if "alpn" in node:
            if not isinstance(node["alpn"], list) or not all(
                isinstance(x, str) and x for x in node["alpn"]
            ):
                raise ConfigError("Invalid Trojan ALPN")
            tls["alpn"] = node["alpn"]
        outbound = {
            "type": "trojan",
            "tag": node["name"],
            "server": node["server"],
            "server_port": port,
            "password": node["password"],
            "tls": tls,
            "domain_resolver": "bootstrap",
        }
        if node.get("udp") is False:
            outbound["network"] = "tcp"
        if "tfo" in node:
            outbound["tcp_fast_open"] = node["tfo"]
        result.append(outbound)
    return result


def make_config(base, text, secret):
    config = copy.deepcopy(base)
    reserved = {
        item["tag"] for item in config["outbounds"] + config.get("endpoints", [])
    }
    nodes = convert_nodes(text, reserved)
    tags = [node["tag"] for node in nodes]
    for outbound in config["outbounds"]:
        if outbound["tag"] == "Proxy":
            outbound["outbounds"] = ["Auto", *tags]
        elif outbound["tag"] == "Auto":
            outbound["outbounds"] = tags
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
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--credentials", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--core", required=True)
    args = parser.parse_args()
    os.umask(0o077)
    args.state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (args.state / ".subscription.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        base = json.loads(args.base.read_text())
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
        config = make_config(base, text, secret)
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
