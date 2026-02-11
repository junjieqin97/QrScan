#!/usr/bin/env python3
"""Suggest a commit scope from changed file paths.

Priority:
1. Staged files
2. Unstaged files
"""

from __future__ import annotations

import argparse
import collections
import json
import pathlib
import re
import subprocess
import sys
from typing import Iterable


def run(cmd: list[str]) -> list[str]:
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def changed_files() -> tuple[list[str], str]:
    staged = run(["git", "diff", "--cached", "--name-only"])
    if staged:
        return staged, "staged"

    unstaged = run(["git", "diff", "--name-only"])
    if unstaged:
        return unstaged, "unstaged"

    untracked = run(["git", "ls-files", "--others", "--exclude-standard"])
    if untracked:
        return untracked, "untracked"

    return [], "none"


def normalize_scope_token(token: str) -> str:
    token = token.lower()
    token = re.sub(r"[^a-z0-9]+", "-", token).strip("-")
    if not token:
        return "chore"
    return token


def infer_scope(path_str: str) -> str:
    path = pathlib.PurePosixPath(path_str)
    parts = list(path.parts)
    if not parts:
        return "chore"

    top = parts[0].lower()

    top_level_map = {
        "qrscan": "app",
        "qrscantests": "tests",
        "qrscanuitests": "ui-tests",
        "docs": "docs",
        ".github": "ci",
        "scripts": "chore",
        "fastlane": "release",
    }

    if top in top_level_map:
        return top_level_map[top]

    if len(parts) >= 2 and parts[0] == "QrScan":
        stem = pathlib.PurePosixPath(parts[1]).stem
        return normalize_scope_token(stem)

    if len(parts) == 1:
        stem = path.stem
        if stem:
            return normalize_scope_token(stem)

    return normalize_scope_token(top)


def rank_scopes(paths: Iterable[str]) -> list[tuple[str, int]]:
    counter: collections.Counter[str] = collections.Counter()
    for p in paths:
        counter[infer_scope(p)] += 1
    return sorted(counter.items(), key=lambda item: (-item[1], item[0]))


def build_result() -> dict:
    files, source = changed_files()
    ranked = rank_scopes(files)
    primary = ranked[0][0] if ranked else "chore"

    return {
        "source": source,
        "files": files,
        "primary_scope": primary,
        "scope_counts": [{"scope": scope, "count": count} for scope, count in ranked],
        "subject_template": f"{primary}: <summary>",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Suggest commit scope from git diff.")
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    args = parser.parse_args()

    result = build_result()

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    print(f"source: {result['source']}")
    print(f"primary_scope: {result['primary_scope']}")

    scope_counts = result["scope_counts"]
    if scope_counts:
        scopes_text = ", ".join(f"{item['scope']}({item['count']})" for item in scope_counts)
    else:
        scopes_text = "none"
    print(f"scope_counts: {scopes_text}")

    print(f"subject_template: {result['subject_template']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
