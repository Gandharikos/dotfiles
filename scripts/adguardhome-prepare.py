#!/usr/bin/env python3
"""Inject runtime-only admin hashes and seed an absent filter cache without network I/O."""
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile

import yaml


def prepare(config_path, credential_path, seed_path):
    users = json.loads(credential_path.read_text())
    if not isinstance(users, list) or not users:
        raise ValueError("Admin credentials required")
    for user in users:
        if (
            not isinstance(user, dict)
            or set(user) != {"name", "password"}
            or not isinstance(user["name"], str)
            or not user["name"]
            or not isinstance(user["password"], str)
            or not re.fullmatch(r"\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}", user["password"])
        ):
            raise ValueError("Invalid admin credentials")
    config = yaml.safe_load(config_path.read_text())
    if not isinstance(config, dict):
        raise ValueError("Invalid configuration")
    filters = config.get("filters", [])
    if (
        len(filters) != 1
        or type(filters[0].get("id")) is not int
        or filters[0]["id"] <= 0
    ):
        raise ValueError("Expected one pinned filter with a positive ID")
    config["users"] = users
    cache = config_path.parent / "data" / "filters" / f"{filters[0]['id']}.txt"
    cache.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if not cache.exists() or cache.stat().st_size == 0:
        # copyfile gives the seed a fresh mtime; AGH uses it for refresh scheduling.
        shutil.copyfile(seed_path, cache)
        cache.chmod(0o600)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=config_path.parent, delete=False) as out:
            temporary = Path(out.name)
            yaml.safe_dump(config, out, sort_keys=False)
            out.flush()
            os.fsync(out.fileno())
        temporary.replace(config_path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        if len(sys.argv) != 4:
            raise ValueError("Expected config, credential and seed paths")
        prepare(*(Path(arg) for arg in sys.argv[1:]))
    except Exception:
        # Do not put YAML contents, password hashes or credential values in journals.
        print("AdGuard preparation failed; refusing to start without validated credentials/cache.", file=sys.stderr)
        sys.exit(1)
