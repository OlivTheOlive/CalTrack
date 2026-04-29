#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
from pathlib import Path


VERSION_RE = re.compile(r"^(?P<maj>\d+)\.(?P<min>\d+)\.(?P<pat>\d+)\+(?P<bld>\d+)$")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Bump pubspec.yaml version safely.")
    p.add_argument(
        "--bump",
        required=True,
        choices=["minor", "patch"],
        help="Bump type: minor => X.(Y+1).0, patch => X.Y.(Z+1)",
    )
    p.add_argument("--build-number", required=True, type=int, help="New build number (+N).")
    p.add_argument(
        "--pubspec",
        default="pubspec.yaml",
        help="Path to pubspec.yaml (default: pubspec.yaml).",
    )
    return p.parse_args()


def main() -> int:
    args = parse_args()
    pubspec_path = Path(args.pubspec)
    text = pubspec_path.read_text(encoding="utf-8")

    m = re.search(r"^version:\s*(?P<ver>\S+)\s*$", text, flags=re.MULTILINE)
    if not m:
        raise SystemExit("Could not find a 'version:' line in pubspec.yaml")

    current = m.group("ver").strip()
    vm = VERSION_RE.match(current)
    if not vm:
        raise SystemExit(f"Unexpected version format: {current!r} (expected X.Y.Z+N)")

    maj = int(vm.group("maj"))
    minor = int(vm.group("min"))
    patch = int(vm.group("pat"))

    if args.bump == "minor":
        minor += 1
        patch = 0
    elif args.bump == "patch":
        patch += 1
    else:
        raise SystemExit(f"Unsupported bump type: {args.bump}")

    build_number = int(args.build_number)
    version_name = f"{maj}.{minor}.{patch}"
    version_full = f"{version_name}+{build_number}"

    new_text = re.sub(
        r"^version:\s*\S+\s*$",
        f"version: {version_full}",
        text,
        flags=re.MULTILINE,
        count=1,
    )
    pubspec_path.write_text(new_text, encoding="utf-8")

    # Shell-friendly output for GitHub Actions
    print(f"VERSION_NAME={version_name}")
    print(f"VERSION_FULL={version_full}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

