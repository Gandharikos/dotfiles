import json
import math
import os
import time
from http.server import BaseHTTPRequestHandler, HTTPServer


def disk_status(path, warning_percent):
    try:
        usage = os.statvfs(path)
        used = usage.f_blocks - usage.f_bfree
        available = max(0, usage.f_bavail)
        # Like df, count only space available to ordinary service users as free.
        total = used + available
        percent = math.ceil(100 * used / total) if total else 100
        inode_percent = None
        if usage.f_files:
            inode_used = usage.f_files - usage.f_ffree
            inode_total = inode_used + max(0, usage.f_favail)
            inode_percent = math.ceil(100 * inode_used / inode_total) if inode_total else 100
        # ProtectSystem=strict makes this service's own mount namespace read-only.
        # Its mount flags must not be mistaken for host filesystem failures.
        return {
            "used_percent": percent,
            "available_bytes": available * usage.f_frsize,
            "inode_used_percent": inode_percent,
            "ok": (
                available > 0
                and percent < warning_percent
                and (inode_percent is None or inode_percent < warning_percent)
            ),
        }
    except OSError as error:
        return {"ok": False, "error": str(error)}


def collect_health(last_success_path, pg_dump_path, max_age_seconds, warning_percent, disk_paths, now=None):
    now = int(time.time()) if now is None else now
    checks = {}
    try:
        with open(last_success_path, encoding="utf-8") as handle:
            last_success = int(handle.read().strip())
        age = now - last_success
        checks["last_success_age_seconds"] = age
        checks["last_success_fresh"] = 0 <= age <= max_age_seconds
    except (OSError, ValueError) as error:
        checks["last_success_error"] = str(error)
        checks["last_success_fresh"] = False

    try:
        checks["postgresql_dump_size"] = os.path.getsize(pg_dump_path)
        checks["postgresql_dump_present"] = checks["postgresql_dump_size"] > 0
    except OSError as error:
        checks["postgresql_dump_error"] = str(error)
        checks["postgresql_dump_present"] = False

    disks = {path: disk_status(path, warning_percent) for path in dict.fromkeys(["/", *disk_paths])}
    checks["disks"] = disks
    checks["disks_ok"] = all(disk["ok"] for disk in disks.values())
    checks["root_disk_used_percent"] = disks["/"].get("used_percent")
    checks["root_disk_ok"] = disks["/"]["ok"]
    ok = all(value for key, value in checks.items() if key.endswith(("_fresh", "_present", "_ok")))
    return {"ok": ok, "checks": checks}


def main():
    config = {
        "last_success_path": os.environ["SELFHOSTED_BACKUP_LAST_SUCCESS"],
        "pg_dump_path": os.environ["SELFHOSTED_BACKUP_PG_DUMP"],
        "max_age_seconds": int(os.environ["SELFHOSTED_BACKUP_MAX_AGE_SECONDS"]),
        "warning_percent": int(os.environ["SELFHOSTED_BACKUP_DISK_WARN_PERCENT"]),
        "disk_paths": json.loads(os.environ.get("SELFHOSTED_BACKUP_DISK_PATHS", '["/"]')),
    }
    if not 1 <= config["warning_percent"] <= 100 or config["max_age_seconds"] <= 0:
        raise ValueError("Invalid backup health thresholds")
    paths = config["disk_paths"]
    if not isinstance(paths, list) or any(not isinstance(path, str) or not os.path.isabs(path) for path in paths):
        raise ValueError("Backup health disk paths must be a JSON list of absolute paths")

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path != "/health":
                self.send_response(404)
                self.end_headers()
                return
            result = collect_health(**config)
            body = json.dumps(result, sort_keys=True).encode("utf-8")
            self.send_response(200 if result["ok"] else 503)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, format, *args):
            return

    HTTPServer(("127.0.0.1", int(os.environ["SELFHOSTED_BACKUP_PORT"])), Handler).serve_forever()


if __name__ == "__main__":
    main()
