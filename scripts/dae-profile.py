"""Render private dae nodes with an ordered, public Clash/Surge policy snapshot."""

import argparse
import ipaddress
import itertools
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import quote, urlencode

import yaml


def require(condition):
    if not condition:
        raise ValueError("Unsupported dae profile input")


def literal(value):
    require(isinstance(value, str) and value and not any(c in value for c in "'\\\r\n\x00"))
    return "'" + value + "'"


def compile_rules(rules, targets):
    """Export public rules, retaining order; merge only adjacent equal matches/actions."""
    terms = []
    fallback = None
    aliases = {name: f"__POLICY_{i}__" for i, name in enumerate(targets)}
    actions = {**aliases, "DIRECT": "direct", "REJECT": "block"}
    for raw in rules:
        if not raw:
            continue
        require(isinstance(raw, str) and fallback is None)
        fields = [x.strip() for x in raw.split(",")]
        kind = fields[0]
        if kind in ("MATCH", "FINAL"):
            require(len(fields) == 2 and fields[1] in actions)
            fallback = actions[fields[1]]
            continue
        require(len(fields) >= 3 and fields[2] in actions)
        value, target = fields[1], actions[fields[2]]
        if kind in ("IP-CIDR", "IP-CIDR6"):
            require(fields[3:] in ([], ["no-resolve"]))
            network = ipaddress.ip_network(value, strict=False)
            require(network.version == (4 if kind == "IP-CIDR" else 6))
            terms.append(("dip", target, literal(str(network))))
            continue
        require(len(fields) == 3)
        if kind == "GEOIP":
            require(value.upper() == "CN")
            terms.append(("dip", target, "geoip:cn"))
        elif kind == "PROCESS-NAME":
            # Host processes only: no attempt to infer a forwarded LAN client's process.
            terms.append(("pname", target, literal(value)))
        else:
            prefix = {"DOMAIN": "full", "DOMAIN-SUFFIX": "suffix", "DOMAIN-KEYWORD": "keyword"}.get(kind)
            require(prefix is not None)
            if prefix != "keyword":
                if not value.isascii():
                    encoded = value.encode("idna").decode("ascii")
                    require(encoded.encode("ascii").decode("idna").lower() == value.lower())
                    value = encoded
                require(len(value) <= 253 and all(re.fullmatch(r"[A-Za-z0-9-]{1,63}", p) for p in value.split(".")))
            else:
                require(re.fullmatch(r"[A-Za-z0-9._-]+", value) is not None)
            terms.append(("domain", target, prefix + ":" + literal(value.lower())))
    require(fallback is not None)
    lines = []
    for (function, target), entries in itertools.groupby(terms, key=lambda x: x[:2]):
        values = (x[2] for x in entries)
        while batch := list(itertools.islice(values, 128)):
            lines.append(f"{function}({', '.join(batch)}) -> {target}")
    return "\n".join([*lines, f"fallback: {fallback}"]), {token: name for name, token in aliases.items()}


def render_nodes(document):
    require(isinstance(document, dict) and isinstance(document.get("proxies"), list) and document["proxies"])
    names, nodes, groups = {}, [], []
    allowed = {"name", "type", "server", "port", "password", "sni", "udp", "skip-cert-verify"}
    for i, node in enumerate(document["proxies"]):
        require(isinstance(node, dict) and not (node.keys() - allowed) and node.get("type") == "trojan")
        for key in ("name", "server", "password"):
            require(isinstance(node.get(key), str) and node[key])
        require(node["name"] not in names and node["name"] not in ("DIRECT", "REJECT"))
        require(type(node.get("port")) is int and 1 <= node["port"] <= 65535)
        # dae's Trojan dialer supports both TCP and UDP; do not silently ignore a TCP-only restriction.
        require(node.get("udp", True) is True)
        require(type(node.get("skip-cert-verify", False)) is bool)
        server = node["server"]
        try:
            address = ipaddress.ip_address(server)
            server = f"[{address}]" if address.version == 6 else str(address)
        except ValueError:
            require(re.fullmatch(r"[A-Za-z0-9.-]+", server) is not None)
        sni = node.get("sni", node["server"])
        require(isinstance(sni, str) and re.fullmatch(r"[A-Za-z0-9.:-]+", sni) is not None)
        query = {"sni": sni}
        if node.get("skip-cert-verify", False):
            query["allowInsecure"] = "1"
        uri = f"trojan://{quote(node['password'], safe='')}@{server}:{node['port']}?{urlencode(query)}"
        alias = f"node_{i}"
        names[node["name"]] = alias
        nodes.append(f"  n{i}: {literal(uri)}")
        groups.append(f"  {alias} {{\n    filter: name(n{i})\n    policy: fixed(0)\n  }}")
    return names, "\n".join(nodes), "\n".join(groups)


def render(template, policy, group_data, parameters, document):
    nodes, node_text, group_text = render_nodes(document)
    groups = group_data["groups"]
    choices = {**group_data["selections"], **parameters["selections"]}
    require(not (groups.keys() & (nodes.keys() | {"DIRECT", "REJECT"})))
    require(choices.keys() <= groups.keys())
    resolved = {**nodes, "DIRECT": "direct", "REJECT": "block"}

    def resolve(name, path):
        if name in resolved:
            return resolved[name]
        require(name in groups and name not in path)
        members = groups[name]
        require(isinstance(members, list) and members and all(isinstance(x, str) for x in members))
        choice = choices.get(name, members[0])
        require(choice in members)
        for member in members:
            resolve(member, path | {name})
        resolved[name] = resolve(choice, path | {name})
        return resolved[name]

    for group in groups:
        resolve(group, set())
    for token, target in group_data["targets"].items():
        require(re.fullmatch(r"__POLICY_[0-9]+__", token) is not None)
        policy = policy.replace(token, resolve(target, set()))
    interfaces = {}
    for side in ("wan", "lan"):
        values = parameters[side]
        require(isinstance(values, list) and all(re.fullmatch(r"[A-Za-z0-9_.:-]+", x) for x in values))
        interfaces[side] = f"{side}_interface: {', '.join(values)}" if values else ""
    require(parameters["wan"] or parameters["lan"])
    domain = parameters["tailnetDomain"]
    require(not domain or re.fullmatch(r"[A-Za-z0-9.-]+", domain))
    replacements = {
        "__NODES__": node_text,
        "__GROUPS__": group_text,
        "__RULES__": policy,
        "__WAN__": interfaces["wan"],
        "__LAN__": interfaces["lan"],
        "__DNS_PORT__": str(parameters["dnsPort"]),
        "__TPROXY_PORT__": str(parameters["tproxyPort"]),
        "__TAILNET_DNS_RULE__": f"qname(suffix:{literal(domain)}) -> tailnet" if domain else "",
        "__TAILNET_ROUTE_RULE__": f"domain(suffix:{literal(domain)}) -> direct" if domain else "",
    }
    require(re.search(r"__POLICY_[0-9]+__", policy) is None)
    require(all(token in replacements for token in re.findall(r"__[A-Z_0-9]+__", template)))
    # Substitute once: a password containing a placeholder-like string is still a password.
    return re.sub(r"__[A-Z_0-9]+__", lambda match: replacements[match[0]], template)


def main():
    parser = argparse.ArgumentParser()
    for name in ("template", "policy", "groups", "parameters", "nodes", "output"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--core", required=True)
    args = parser.parse_args()
    os.umask(0o077)
    text = render(
        args.template.read_text(), args.policy.read_text(), json.loads(args.groups.read_text()),
        json.loads(args.parameters.read_text()), yaml.safe_load(args.nodes.read_text()),
    )
    fd, temporary = tempfile.mkstemp(prefix=".config-", suffix=".dae", dir=args.output.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
        result = subprocess.run([args.core, "validate", "-c", temporary], capture_output=True, timeout=60)
        require(result.returncode == 0)
        os.replace(temporary, args.output)
    finally:
        Path(temporary).unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, yaml.YAMLError, subprocess.SubprocessError):
        # Core and parser errors may contain node URIs. Never forward their diagnostics.
        raise SystemExit("dae profile generation failed; no replacement configuration was published") from None
