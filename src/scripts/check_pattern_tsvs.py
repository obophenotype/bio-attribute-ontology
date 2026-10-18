#!/usr/bin/env python3
"""QC for the DOSDP pattern data TSVs, run as part of `make test`.

Fails if
- a defined_class ID appears in more than one row, within one TSV or across TSVs
  (dosdp emits both rows, so a repeated ID with different fillers silently gets
  two equivalence axioms; see #470);
- a pattern variable declared under `vars:` has no column in the pattern's TSV
  (dosdp only warns and drops every axiom and annotation that uses the variable,
  leaving label-only classes; see #474).

Usage: check_pattern_tsvs.py <dosdp-patterns dir> <pattern data dir>
"""
import csv
import sys
from collections import defaultdict
from pathlib import Path

import yaml


def main(pattern_dir: Path, data_dir: Path) -> int:
    errors = []
    seen = defaultdict(list)

    for tsv in sorted(data_dir.glob("*.tsv")):
        with tsv.open(newline="", encoding="utf-8") as f:
            reader = csv.reader(f, delimiter="\t")
            header = next(reader, [])
            if "defined_class" not in header:
                errors.append(f"{tsv.name}: no defined_class column")
                continue
            col = header.index("defined_class")
            for lineno, row in enumerate(reader, start=2):
                if len(row) > col and row[col].strip():
                    seen[row[col].strip()].append(f"{tsv.name}:{lineno}")

        yml = pattern_dir / f"{tsv.stem}.yaml"
        if not yml.exists():
            errors.append(f"{tsv.name}: no pattern file {yml.name}")
            continue
        pattern = yaml.safe_load(yml.read_text(encoding="utf-8")) or {}
        for var in (pattern.get("vars") or {}):
            if var not in header:
                errors.append(f"{tsv.name}: no column for pattern variable '{var}' declared in {yml.name}")

    for cls, places in sorted(seen.items()):
        if len(places) > 1:
            errors.append(f"{cls} defined more than once: {', '.join(places)}")

    for e in errors:
        print(f"ERROR {e}")
    print(f"check_pattern_tsvs: {len(errors)} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1]), Path(sys.argv[2])))
