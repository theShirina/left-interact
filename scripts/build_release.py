#!/usr/bin/env python3
"""Build a deterministic Left Interact release ZIP and checksum."""

from __future__ import annotations

import argparse
import hashlib
import re
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = ("LeftInteract.lua", "LeftInteract.toc", "README.txt", "LICENSE")
FIXED_TIMESTAMP = (2026, 1, 1, 0, 0, 0)


def version_from_toc() -> str:
    toc = (ROOT / "LeftInteract.toc").read_text(encoding="utf-8")
    match = re.search(r"^## Version:\s*(.+?)\s*$", toc, re.MULTILINE)
    if not match:
        raise RuntimeError("LeftInteract.toc has no Version field")
    return match.group(1)


def add_file(archive: zipfile.ZipFile, source: Path, archive_name: str) -> None:
    info = zipfile.ZipInfo(archive_name, FIXED_TIMESTAMP)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o100644 << 16
    archive.writestr(info, source.read_bytes())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=ROOT / "dist")
    args = parser.parse_args()

    version = version_from_toc()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    destination = args.output_dir / f"LeftInteract-v{version}.zip"

    with tempfile.NamedTemporaryFile(dir=args.output_dir, suffix=".zip.tmp", delete=False) as handle:
        temporary = Path(handle.name)

    try:
        with zipfile.ZipFile(temporary, "w") as archive:
            for name in FILES:
                add_file(archive, ROOT / name, f"LeftInteract/{name}")
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)

    with zipfile.ZipFile(destination) as archive:
        expected_members = [f"LeftInteract/{name}" for name in FILES]
        if archive.namelist() != expected_members:
            raise RuntimeError(f"Unexpected ZIP members: {archive.namelist()}")
        bad_file = archive.testzip()
        if bad_file:
            raise RuntimeError(f"Corrupt ZIP member: {bad_file}")

    checksum = hashlib.sha256(destination.read_bytes()).hexdigest()
    checksum_path = destination.with_suffix(destination.suffix + ".sha256")
    checksum_path.write_text(f"{checksum}  {destination.name}\n", encoding="ascii")

    print(destination)
    print(checksum_path)
    print(f"SHA-256: {checksum}")


if __name__ == "__main__":
    main()
