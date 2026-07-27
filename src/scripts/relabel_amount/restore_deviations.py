#!/usr/bin/env python3
"""Step 2 of the level->amount relabel: restore explicit names where needed.

`blank_level_names.py` blanks every `level of ...` label so dosdp derives it
from the pattern. For most rows that is exactly right. For the rows listed in
deviations.tsv the pattern output differs from the curated label by more than
the level->amount word - a suppressed location, different lipid notation, or a
different name for the entity - so the curated label is put back, with only
"level of " swapped for "amount of ".

This keeps the branch to a single semantic change: one word per label.

Usage:
    restore_deviations.py <repo_root> <deviations.tsv> [--dry-run]
"""
import os
import sys

TARGETS = [
    'entity_attribute_location.tsv',
    'attribute_location_during_activity.tsv',
    'chemical_role_attribute_location.tsv',
    'entity_response_quality_in_location.tsv',
]


def load_intended(path: str) -> dict[str, str]:
    """Map OBA id -> the label to restore (column 4 of deviations.tsv)."""
    intended = {}
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            curie, _old, _new, want = line.rstrip('\n').split('\t')
            intended[curie] = want
    return intended


def process(path: str, intended: dict[str, str], dry_run: bool) -> list[str]:
    with open(path, encoding='utf-8', newline='') as handle:
        text = handle.read()

    had_trailing_newline = text.endswith('\n')
    lines = text.split('\n')
    if had_trailing_newline:
        lines = lines[:-1]

    header = lines[0].split('\t')
    name_idx = header.index('defined_class_name')

    restored = []
    out = [lines[0]]

    for line in lines[1:]:
        fields = line.split('\t')
        curie = fields[0] if fields else ''

        if curie not in intended or len(fields) <= name_idx:
            out.append(line)
            continue

        # Only fill a name we previously blanked; never overwrite a curated one.
        if fields[name_idx] != '':
            out.append(line)
            continue

        fields[name_idx] = intended[curie]
        restored.append(curie)
        out.append('\t'.join(fields))

    if not dry_run:
        result = '\n'.join(out) + ('\n' if had_trailing_newline else '')
        with open(path, 'w', encoding='utf-8', newline='') as handle:
            handle.write(result)

    return restored


def main() -> None:
    repo_root, deviations_path = sys.argv[1], sys.argv[2]
    dry_run = '--dry-run' in sys.argv
    intended = load_intended(deviations_path)
    pattern_dir = os.path.join(repo_root, 'src/patterns/data/default')

    all_restored: list[str] = []
    for name in TARGETS:
        restored = process(os.path.join(pattern_dir, name), intended, dry_run)
        all_restored.extend(restored)
        print(f'{len(restored):>6} restored in {name}')

    print(f'{len(all_restored):>6} of {len(intended)} deviations restored'
          f'{" (dry run)" if dry_run else ""}')

    unmatched = sorted(set(intended) - set(all_restored))
    if unmatched:
        print(f'\nNOT RESTORED ({len(unmatched)}):')
        for curie in unmatched[:20]:
            print(f'  {curie}\t{intended[curie]}')


if __name__ == '__main__':
    main()
