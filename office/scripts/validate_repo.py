#!/usr/bin/env python3
"""Company-grade repo hygiene checks. Exits non-zero on any violation.

Checks:
  1. Required standard files exist (LICENSE, README, ACTIVATE, ...).
  2. Every office/staff/*.md and office/playbooks/*.md is referenced in
     the canonical docs (office/README.md, office/AGENTS.md, AGENTS.md).
  3. ACTIVATE.md carries the trigger phrase.
  4. No trailing whitespace in tracked markdown files.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
errors = []

REQUIRED = [
    "LICENSE",
    "README.md",
    "ACTIVATE.md",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "SECURITY.md",
    "CHANGELOG.md",
    ".github/CODEOWNERS",
    ".github/PULL_REQUEST_TEMPLATE.md",
    "office/HOUSE_RULES.md",
    "office/README.md",
    "office/AGENTS.md",
    "memory/INDEX.md",
]
for f in REQUIRED:
    if not (ROOT / f).exists():
        errors.append(f"missing required file: {f}")

canon = ""
for f in ["office/README.md", "office/AGENTS.md", "AGENTS.md", "README.md"]:
    p = ROOT / f
    if p.exists():
        canon += "\n" + p.read_text(encoding="utf-8")
canon_n = canon.lower().replace("-", "").replace("_", "")


def referenced(stem: str) -> bool:
    return stem.lower().replace("-", "").replace("_", "") in canon_n


for d in ["office/staff", "office/playbooks"]:
    for md in sorted((ROOT / d).glob("*.md")):
        if not referenced(md.stem):
            errors.append(f"unreferenced file: {md.relative_to(ROOT)}")

act = (ROOT / "ACTIVATE.md").read_text(encoding="utf-8")
if "github public repo" not in act.lower():
    errors.append("ACTIVATE.md missing the trigger phrase")

for md in sorted(ROOT.rglob("*.md")):
    if ".git/" in str(md):
        continue
    for i, line in enumerate(
        md.read_text(encoding="utf-8").splitlines(), 1
    ):
        if line != line.rstrip():
            errors.append(
                f"trailing whitespace: {md.relative_to(ROOT)}:{i}"
            )
            break

if errors:
    print("validate_repo.py FAILED:")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("validate_repo.py OK")
