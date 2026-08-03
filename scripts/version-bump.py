#!/usr/bin/env python3

from __future__ import annotations

import datetime as dt
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def detect_current_version() -> str:
    spec = read_text(ROOT / "minectl.spec")
    match = re.search(r"^Version:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*$", spec, re.M)
    if not match:
        raise RuntimeError("Could not detect current version from minectl.spec")
    return match.group(1)


def prompt_new_version(current_version: str) -> str:
    print(f"Current version: {current_version}")
    new_version = input("What would you like to update it to? ").strip()
    if not new_version:
        raise SystemExit("No version provided.")
    if not SEMVER_RE.match(new_version):
        raise SystemExit(f"Invalid version: {new_version!r} (expected MAJOR.MINOR.PATCH)")
    if new_version == current_version:
        raise SystemExit("New version matches the current version; nothing to do.")
    return new_version


def prompt_release_notes(new_version: str) -> list[str]:
    print("Enter changelog notes, one per line. Submit a blank line to finish:")
    notes: list[str] = []
    while True:
        try:
            line = input().strip()
        except EOFError:
            break
        if not line:
            break
        line = line.lstrip("- ").strip()
        if line:
            notes.append(line)

    if not notes:
        notes = [f"Version bump to {new_version}."]

    return notes


def replace_once(text: str, pattern: str, replacement: str, *, label: str) -> str:
    new_text, count = re.subn(pattern, replacement, text, count=1, flags=re.M)
    if count != 1:
        raise RuntimeError(f"Expected to update {label} exactly once; updated {count} times")
    return new_text


def replace_all_semver(text: str, new_version: str, *, label: str) -> str:
    new_text, count = re.subn(r"\b\d+\.\d+\.\d+\b", new_version, text)
    if count == 0:
        raise RuntimeError(f"Did not find any version strings to update in {label}")
    return new_text


def update_minectl(new_version: str) -> None:
    path = ROOT / "minectl"
    text = read_text(path)
    text = replace_once(
        text,
        r'^MINECTL_VERSION="[^"]+"$',
        f'MINECTL_VERSION="{new_version}"',
        label="minectl CLI version",
    )
    write_text(path, text)


def update_build_script(new_version: str) -> None:
    path = ROOT / "build-rpm.sh"
    text = read_text(path)
    text = replace_once(
        text,
        r'^VERSION="[^"]+"$',
        f'VERSION="{new_version}"',
        label="build-rpm.sh version",
    )
    write_text(path, text)


def update_spec(new_version: str, notes: list[str]) -> None:
    path = ROOT / "minectl.spec"
    text = read_text(path)
    text = replace_once(
        text,
        r'^Version:\s*.*$',
        f'Version:        {new_version}',
        label="minectl.spec version",
    )

    changelog_entry = [
        f"* {dt.datetime.now().strftime('%a %b %d %Y')} minectl <noreply@github.com> - {new_version}-1",
        *[f"- {note}" for note in notes],
        "",
    ]
    marker = "%changelog\n"
    if marker not in text:
        raise RuntimeError("Could not find %changelog section in minectl.spec")
    text = text.replace(marker, marker + "\n".join(changelog_entry) + "\n", 1)
    write_text(path, text)


def update_changelog(new_version: str, notes: list[str]) -> None:
    path = ROOT / "CHANGELOG.md"
    text = read_text(path)
    marker = "# Changelog\n\n"
    if not text.startswith(marker):
        raise RuntimeError("CHANGELOG.md does not start with '# Changelog'")

    section = [
        f"## {new_version}",
        "",
        "### Release Notes",
        "",
        *[f"- {note}" for note in notes],
        "",
    ]
    text = marker + "\n".join(section) + text[len(marker):]
    write_text(path, text)


def update_docs_examples(new_version: str) -> None:
    for rel_path in ("BUILD.md", "REPO.md"):
        path = ROOT / rel_path
        if not path.exists():
            continue
        text = read_text(path)
        updated = replace_all_semver(text, new_version, label=rel_path)
        write_text(path, updated)


def main() -> int:
    current_version = detect_current_version()
    new_version = prompt_new_version(current_version)
    notes = prompt_release_notes(new_version)

    update_minectl(new_version)
    update_build_script(new_version)
    update_spec(new_version, notes)
    update_changelog(new_version, notes)
    update_docs_examples(new_version)

    print()
    print(f"Updated version from {current_version} to {new_version} in:")
    print("  - minectl")
    print("  - build-rpm.sh")
    print("  - minectl.spec")
    print("  - CHANGELOG.md")
    print("  - BUILD.md")
    print("  - REPO.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
