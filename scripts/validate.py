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
PUBLIC_README = ROOT / "README.md"
CHANGELOG = ROOT / "CHANGELOG.md"


class ValidationError(Exception):
    """Raised when a release invariant is not met."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def toc_value(text: str, key: str) -> str:
    match = re.search(rf"^## {re.escape(key)}:\s*(.+?)\s*$", text, re.MULTILINE)
    if not match:
        raise ValidationError(f"Missing TOC field: {key}")
    return match.group(1)


def main() -> int:
    toc = TOC.read_text(encoding="utf-8")
    lua = LUA.read_text(encoding="utf-8")
    package_readme = PACKAGE_README.read_text(encoding="utf-8")
    public_readme = PUBLIC_README.read_text(encoding="utf-8")
    changelog = CHANGELOG.read_text(encoding="utf-8")

    interface = toc_value(toc, "Interface")
    version = toc_value(toc, "Version")

    require(interface == "30300", f"Expected Interface 30300, got {interface}")
    require(bool(re.fullmatch(r"\d+\.\d+\.\d+", version)), f"Invalid semantic version: {version}")
    require(package_readme.startswith(f"LEFT INTERACT {version}\n"), "README.txt version differs from TOC")
    require(f'local ADDON_VERSION = "{version}"' in lua, "GUI source version differs from TOC")
    require("GetAddOnMetadata" not in lua, "GUI version must not use restart-cached addon metadata")

    toc_files = [
        line.strip()
        for line in toc.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    require(toc_files == ["LeftInteract.lua"], f"Unexpected TOC file list: {toc_files}")
    for name in toc_files:
        require((ROOT / name).is_file(), f"TOC references missing file: {name}")

    try:
        ast.parse(lua)
    except Exception as exc:
        raise ValidationError(f"Lua syntax error: {exc}") from exc

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

    ground_spell_tokens = (
        "#showtooltip Death and Decay",
        "/cast [@cursor] Death and Decay",
        "@mouseover targets a unit",
    )
    require("GROUND-TARGET SPELLS" in lua, "Ground-target notice missing from settings GUI")
    require("SELECT TO COPY" in lua, "Ground-target macro copy button missing from settings GUI")
    require("HighlightText" in lua, "Ground-target macro copy selection behavior missing")
    require("groundFallback:SetWidth(410)" in lua, "Ground-target copy help has no bounded width")
    require("SELECT TO COPY, then Ctrl+C.\\n@mouseover targets a unit" in lua, "Ground-target copy help must use two lines")
    require("GROUND-TARGET SPELLS" in package_readme, "Ground-target section missing from README.txt")
    require("## Ground-target spells on Ascension" in public_readme, "Ground-target section missing from README.md")
    require("SELECT TO COPY" in package_readme, "README.txt macro-copy instructions missing")
    require("SELECT TO COPY" in public_readme, "README.md macro-copy instructions missing")
    normalized_ground_sources = (
        ("settings GUI", " ".join(lua.replace("`", "").split())),
        ("README.txt", " ".join(package_readme.replace("`", "").split())),
        ("README.md", " ".join(public_readme.replace("`", "").split())),
    )
    for token in ground_spell_tokens:
        for source_name, source_text in normalized_ground_sources:
            require(token in source_text, f"{source_name} ground-target guidance missing: {token}")

    require("CreateChangelogPage" in lua, "In-game changelog page missing")
    require("WHAT'S NEW" in lua, "In-game changelog button missing")
    require("BACK TO SETTINGS" in lua, "Changelog back-navigation button missing")
    require("LeftInteractChangelogFrame" not in lua, "Changelog must not create a second top-level window")
    normalized_lua = " ".join(lua.replace("`", "").split())
    version_entries = re.findall(r"^## \[(\d+\.\d+\.\d+)\] - (\d{4}-\d{2}-\d{2})$", changelog, re.MULTILINE)
    require(bool(version_entries), "CHANGELOG.md contains no release entries")
    for release_version, release_date in version_entries:
        require(f"v{release_version} - {release_date}" in normalized_lua, f"In-game changelog missing v{release_version}")
    changelog_bullets = re.findall(r"^- (.+)$", changelog, re.MULTILINE)
    for bullet in changelog_bullets:
        normalized_bullet = " ".join(bullet.replace("`", "").split())
        require(normalized_bullet in normalized_lua, f"In-game changelog missing entry: {normalized_bullet}")

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
