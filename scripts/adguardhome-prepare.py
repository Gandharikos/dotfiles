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


def prepare(config_path, credential_path, seed_path=None, *, seeds=None):
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
        not isinstance(filters, list)
        or not filters
        or any(not isinstance(f, dict) or type(f.get("id")) is not int or f["id"] <= 0 for f in filters)
        or len({f["id"] for f in filters}) != len(filters)
    ):
        raise ValueError("Expected unique positive filter IDs")
    if seed_path is not None:
        if seeds is not None or len(filters) != 1:
            raise ValueError("Legacy seed requires exactly one filter")
        seeds = {str(filters[0]["id"]): str(seed_path)}
    if not isinstance(seeds, dict) or set(seeds) != {str(f["id"]) for f in filters}:
        raise ValueError("Expected exactly one pinned seed per filter")
    paths = {}
    for identifier, value in seeds.items():
        if not isinstance(value, str) or not Path(value).is_absolute():
            raise ValueError("Expected absolute seed path")
        path = Path(value)
        if not path.is_file() or path.stat().st_size == 0:
            raise ValueError("Missing or empty pinned seed")
        paths[identifier] = path
    config["users"] = users
    for identifier, source in paths.items():
        cache = config_path.parent / "data" / "filters" / f"{identifier}.txt"
        cache.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        if not cache.exists() or cache.stat().st_size == 0:
            # Atomic publication and fresh mtime; AGH uses mtime for refresh scheduling.
            temporary_seed = None
            try:
                with tempfile.NamedTemporaryFile(dir=cache.parent, delete=False) as out:
                    temporary_seed = Path(out.name)
                    with source.open("rb") as incoming:
                        shutil.copyfileobj(incoming, out)
                    out.flush()
                    os.fsync(out.fileno())
                temporary_seed.replace(cache)
            finally:
                if temporary_seed is not None:
                    temporary_seed.unlink(missing_ok=True)
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
        if len(sys.argv) == 4:
            prepare(*(Path(arg) for arg in sys.argv[1:]))
        elif len(sys.argv) == 5 and sys.argv[3] == "--seeds-json":
            prepare(Path(sys.argv[1]), Path(sys.argv[2]), seeds=json.loads(Path(sys.argv[4]).read_text()))
        else:
            raise ValueError("Expected config, credential and seed paths or --seeds-json manifest")
    except Exception:
        # Do not put YAML contents, password hashes or credential values in journals.
        print("AdGuard preparation failed; refusing to start without validated credentials/cache.", file=sys.stderr)
        sys.exit(1)
