#!/usr/bin/env python3
"""Validate Left Interact source and release metadata."""

from __future__ import annotations

import re
import sys
from pathlib import Path

from luaparser import ast

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "LeftInteract.toc"
LUA = ROOT / "LeftInteract.lua"
PACKAGE_README = ROOT / "README.txt"


class ValidationError(Exception):
    """Raised when a release invariant is not met."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def toc_value(text: str, key: str) -> str:
    match = re.search(rf"^## {re.escape(key)}:\s*(.+?)\s*$", text, re.MULTILINE)
    if not match:
        raise AssertionError(f"Missing TOC field: {key}")
    return match.group(1)


def main() -> int:
    toc = TOC.read_text(encoding="utf-8")
    lua = LUA.read_text(encoding="utf-8")
    package_readme = PACKAGE_README.read_text(encoding="utf-8")

    interface = toc_value(toc, "Interface")
    version = toc_value(toc, "Version")

    require(interface == "30300", f"Expected Interface 30300, got {interface}")
    require(bool(re.fullmatch(r"\d+\.\d+\.\d+", version)), f"Invalid semantic version: {version}")
    require(package_readme.startswith(f"LEFT INTERACT {version}\n"), "README.txt version differs from TOC")

    toc_files = [
        line.strip()
        for line in toc.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    require(toc_files == ["LeftInteract.lua"], f"Unexpected TOC file list: {toc_files}")
    for name in toc_files:
        require((ROOT / name).is_file(), f"TOC references missing file: {name}")

    ast.parse(lua)

    required_tokens = (
        'SetOverrideBinding(controller, true, "BUTTON1"',
        'SetOverrideBinding(controller, true, "BUTTON2"',
        'SetOverrideBinding(controller, true, "SHIFT-BUTTON1"',
        'SetOverrideBinding(controller, true, "SHIFT-BUTTON2"',
        "ClearOverrideBindings(controller)",
        "InCombatLockdown",
        "CursorHasItem",
        "CreateOptionsGUI",
        "CreateMinimapButton",
    )
    for token in required_tokens:
        require(token in lua, f"Required compatibility behavior missing: {token}")

    forbidden_tokens = ("api_key", "password =", "token =", "webhook")
    lowered = lua.lower()
    for token in forbidden_tokens:
        require(token not in lowered, f"Possible secret-bearing token found: {token}")

    print(f"Validated Left Interact {version} (Interface {interface})")
    print("Lua syntax: PASS")
    print("Metadata and compatibility guards: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValidationError, OSError, SyntaxError) as exc:
        print(f"Validation failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
