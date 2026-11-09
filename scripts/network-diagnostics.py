"""Read-only Linux network inventory; never read credentials, configs or journals."""

import json
import os
import re
import subprocess
from pathlib import Path

SERVICES = (
    "NetworkManager",
    "iwd",
    "systemd-networkd",
    "systemd-resolved",
    "tailscaled",
    "sing-box",
    "mihomo",
)
SERVICE_PROPERTIES = ("LoadState", "ActiveState", "SubState", "MainPID", "NRestarts")
SYSCTLS = (
    "net.ipv4.tcp_available_congestion_control",
    "net.ipv4.tcp_congestion_control",
    "net.core.default_qdisc",
    "net.ipv4.tcp_mtu_probing",
    "net.ipv4.tcp_fastopen",
    "net.ipv4.conf.all.rp_filter",
    "net.ipv4.conf.default.rp_filter",
    "net.ipv6.conf.all.accept_ra",
    "net.ipv6.conf.default.accept_ra",
)


class Probe:
    def __init__(self):
        self.errors = []

    def unavailable(self, command, reason):
        self.errors.append({"command": command, "reason": reason})

    def text(self, command):
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                errors="replace",
                timeout=5,
                check=False,
                stdin=subprocess.DEVNULL,
                env={
                    **os.environ,
                    "LC_ALL": "C",
                    "SYSTEMD_COLORS": "0",
                    "SYSTEMD_PAGER": "",
                },
            )
        except subprocess.TimeoutExpired:
            self.unavailable(command, "timed out")
            return None
        except OSError:
            self.unavailable(command, "could not execute")
            return None
        if result.returncode:
            # Error output may contain sensitive context; never relay it.
            self.unavailable(command, "query failed")
            return None
        return result.stdout.strip()

    def rows(self, command, key=None):
        text = self.text(command)
        if text is None:
            return None
        try:
            data = json.loads(text)
            if key is not None:
                data = data.get(key) if isinstance(data, dict) else None
            if not isinstance(data, list) or not all(
                isinstance(row, dict) for row in data
            ):
                raise ValueError
        except ValueError:
            self.unavailable(command, "unsupported JSON response")
            return None
        return data


def select(row, keys):
    return {
        key: row[key]
        for key in keys
        if key in row
        and (row[key] is None or isinstance(row[key], (str, int, float, bool)))
    }


def selected_rows(rows, keys):
    return None if rows is None else [select(row, keys) for row in rows]


def route_summary(rows):
    if rows is None:
        return None
    groups = {}
    for row in rows:
        row = select(row, ("table", "dev", "protocol", "type", "dst"))
        key = (
            str(row.get("table", "main")),
            row.get("dev"),
            row.get("protocol"),
            row.get("type", "unicast"),
        )
        if key not in groups:
            groups[key] = dict(zip(("table", "device", "protocol", "type"), key))
            groups[key].update(routes=0, default_routes=0)
        groups[key]["routes"] += 1
        groups[key]["default_routes"] += row.get("dst") in (
            "default",
            "0.0.0.0/0",
            "::/0",
        )
    return sorted(groups.values(), key=lambda row: json.dumps(row, sort_keys=True))


def rule_summary(rows):
    if rows is None:
        return None
    return [
        {
            **select(
                row, ("priority", "table", "fwmark", "fwmask", "iif", "oif", "action")
            ),
            "source_scoped": row.get("src", "all") not in ("all", "0.0.0.0/0", "::/0"),
            "destination_scoped": row.get("dst", "all")
            not in ("all", "0.0.0.0/0", "::/0"),
        }
        for row in rows
    ]


def resolved_summary(rows):
    if rows is None:
        return None
    result = []
    for row in rows:
        if any(
            not isinstance(row.get(key, []), list)
            for key in ("servers", "searchDomains")
        ):
            return None
        item = select(
            row,
            (
                "ifindex",
                "ifname",
                "llmnr",
                "mDNS",
                "dnssec",
                "dnsOverTLS",
                "resolvConfMode",
            ),
        )
        item["servers"] = [
            select(server, ("addressString", "port", "ifindex"))
            for server in row.get("servers", [])
            if isinstance(server, dict)
        ]
        item["domains"] = [
            select(domain, ("name", "routeOnly"))
            for domain in row.get("searchDomains", [])
            if isinstance(domain, dict)
        ]
        result.append(item)
    return result


def service_status(probe, unit, user=False):
    command = ["systemctl"] + (["--user"] if user else [])
    command += [
        "show",
        "--no-pager",
        "--property=" + ",".join(SERVICE_PROPERTIES),
        unit,
    ]
    text = probe.text(command)
    if text is None:
        return None
    properties = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator and key in SERVICE_PROPERTIES:
            properties[key] = value
    return properties


def link_target(path):
    try:
        return os.readlink(path)
    except OSError:
        return None


def collect(probe=None):
    probe = probe or Probe()
    report = {
        "schema_version": 1,
        "kernel": os.uname().release,
        "running_system": link_target("/run/current-system"),
        "booted_system": link_target("/run/booted-system"),
        "services": {
            name: service_status(probe, f"{name}.service") for name in SERVICES
        },
        "user_rex": service_status(probe, "rex.service", user=True),
    }
    root = Path(__file__).resolve().parents[1]
    revision = probe.text(["git", "-C", str(root), "rev-parse", "HEAD"])
    report["checkout_revision"] = (
        revision if revision and re.fullmatch(r"[0-9a-f]{40,64}", revision) else None
    )
    report["links"] = selected_rows(
        probe.rows(["ip", "-j", "link", "show"]),
        ("ifname", "operstate", "mtu", "master", "link_type"),
    )
    report["qdiscs"] = selected_rows(
        probe.rows(["tc", "-j", "qdisc", "show"]),
        ("dev", "kind", "handle", "parent", "root"),
    )
    report["networkd"] = selected_rows(
        probe.rows(["networkctl", "--json=short", "list", "--no-pager"], "Interfaces"),
        ("Name", "Type", "OperationalState", "AdministrativeState", "NetworkFile"),
    )
    devices = probe.text(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"])
    report["network_manager"] = (
        None
        if devices is None
        else [
            dict(zip(("device", "type", "state"), line.split(":", 2)))
            for line in devices.splitlines()
            if len(line.split(":", 2)) == 3
        ]
    )
    resolved_command = ["resolvectl", "--json=short", "status"]
    resolved = probe.rows(resolved_command)
    report["resolved"] = resolved_summary(resolved)
    if resolved is not None and report["resolved"] is None:
        probe.unavailable(resolved_command, "unsupported DNS response")
    report["routing"] = {
        family: {
            "rules": rule_summary(probe.rows(["ip", "-j", flag, "rule", "show"])),
            "routes": route_summary(
                probe.rows(["ip", "-j", flag, "route", "show", "table", "all"])
            ),
        }
        for family, flag in (("ipv4", "-4"), ("ipv6", "-6"))
    }
    report["next_hops"] = selected_rows(
        probe.rows(["ip", "-j", "nexthop", "show"]), ("id", "dev", "protocol")
    )
    values = probe.text(["sysctl", "-e", *SYSCTLS])
    report["sysctls"] = {}
    for line in (values or "").splitlines():
        key, separator, value = line.partition("=")
        if separator and key.strip() in SYSCTLS:
            report["sysctls"][key.strip()] = value.strip()
    report["unavailable_sysctls"] = [
        key for key in SYSCTLS if key not in report["sysctls"]
    ]
    report["errors"] = probe.errors
    return report


if __name__ == "__main__":
    print(json.dumps(collect(), ensure_ascii=False, indent=2))
