#!/usr/bin/env python3
"""Wait for native tailscaled readiness without logging identity/status data."""

import json
import subprocess
import sys
import time


def wait_running(tailscale, attempts=30):
    for attempt in range(attempts):
        try:
            result = subprocess.run(
                [tailscale, "status", "--json"],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=2,
            )
            status = json.loads(result.stdout)
            if isinstance(status, dict) and status.get("BackendState") == "Running":
                return True
        except (OSError, ValueError, subprocess.SubprocessError):
            pass
        if attempt + 1 < attempts:
            time.sleep(1)
    return False


if __name__ == "__main__":
    if len(sys.argv) != 2 or not wait_running(sys.argv[1]):
        print("Native tailscaled did not become ready within the polling budget.", file=sys.stderr)
        sys.exit(1)
