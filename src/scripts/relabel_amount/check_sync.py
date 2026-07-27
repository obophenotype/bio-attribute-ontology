#!/usr/bin/env python3
"""Verify the committed definitions.owl is in sync with the DOSDP pattern TSVs.

Every `defined_class` in every pattern TSV should have a label in the baseline,
and every TSV row that carries an explicit `defined_class_name` should match
that label exactly. Divergence means definitions.owl is stale and the baseline
cannot be trusted.

Usage:
    check_sync.py <labels.tsv> <repo_root>
"""
import csv
import glob
import os
import sys


def load_labels(path: str) -> dict[str, str]:
    labels = {}
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            curie, _, label = line.rstrip('\n').partition('\t')
            labels[curie] = label
    return labels


def main() -> None:
    labels_path, repo_root = sys.argv[1], sys.argv[2]
    labels = load_labels(labels_path)

    missing, mismatched, total = [], [], 0
    pattern_dir = os.path.join(repo_root, 'src/patterns/data/default')

    for tsv_path in sorted(glob.glob(os.path.join(pattern_dir, '*.tsv'))):
        with open(tsv_path, encoding='utf-8', newline='') as handle:
            for row in csv.DictReader(handle, delimiter='\t'):
                defined_class = (row.get('defined_class') or '').strip()
                if not defined_class:
                    continue
                total += 1
                name = os.path.basename(tsv_path)
                if defined_class not in labels:
                    missing.append((name, defined_class))
                    continue
                explicit = (row.get('defined_class_name') or '').strip()
                if explicit and explicit != labels[defined_class]:
                    mismatched.append(
                        (name, defined_class, explicit, labels[defined_class])
                    )

    print(f'TSV rows checked:        {total}')
    print(f'missing from baseline:   {len(missing)}')
    print(f'label != defined_class_name: {len(mismatched)}')

    for name, defined_class in missing[:20]:
        print(f'  MISSING  {name}  {defined_class}')
    for name, defined_class, explicit, actual in mismatched[:20]:
        print(f'  MISMATCH {name}  {defined_class}')
        print(f'           tsv: {explicit!r}')
        print(f'           owl: {actual!r}')


if __name__ == '__main__':
    main()
