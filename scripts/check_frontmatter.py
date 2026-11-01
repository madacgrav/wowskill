#!/usr/bin/env python3
"""Stdlib-only mirror of skill-creator's quick_validate rules (used when PyYAML is unavailable)."""
import pathlib
import re
import sys

ALLOWED = {"name", "description", "license", "allowed-tools", "metadata", "compatibility"}


def main(skill_dir: str) -> int:
    root = pathlib.Path(skill_dir)
    errors = []
    skill_mds = [p for p in root.rglob("SKILL.md") if "__pycache__" not in p.parts and "node_modules" not in p.parts]
    if len(skill_mds) != 1:
        errors.append(f"expected exactly one SKILL.md under {root}, found {len(skill_mds)}")
    text = (root / "SKILL.md").read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        print("FAIL: no YAML frontmatter")
        return 1
    fields = dict(re.findall(r"^([A-Za-z-]+):[ \t]*(.*)$", m.group(1), re.M))
    for key in fields:
        if key not in ALLOWED:
            errors.append(f"unexpected frontmatter key: {key}")
    name = fields.get("name", "")
    desc = fields.get("description", "")
    if not name:
        errors.append("missing name")
    elif not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name) or len(name) > 64:
        errors.append(f"invalid name: {name!r}")
    if not desc:
        errors.append("missing description")
    elif len(desc) > 1024 or "<" in desc or ">" in desc:
        errors.append(f"invalid description (len={len(desc)}, angle brackets not allowed)")
    if "compatibility" in fields and len(fields["compatibility"]) > 500:
        errors.append("compatibility longer than 500 chars")
    for e in errors:
        print("FAIL:", e)
    if not errors:
        print("Skill frontmatter is valid")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))
