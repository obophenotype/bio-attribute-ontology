#!/usr/bin/env python3
"""Step 1 of the level->amount relabel: blank every `level of ...` label.

For each DOSDP pattern TSV, every row whose `defined_class_name` starts with
"level of " has that column emptied, so dosdp-tools falls back to the pattern's
own `name:` template (which renders the PATO:0000070 filler as "amount").
The old label is preserved as an exact synonym.

Blanking is applied indiscriminately here on purpose: which rows genuinely
need to keep an explicit name is discovered empirically by rebuilding and
diffing against the baseline, not guessed from the TSV. `restore_deviations.py`
then puts explicit names back on the rows the build shows need them.

Files whose pattern has no `data_list_vars` (and therefore no exact_synonyms
column) are still blanked, but the synonym must be carried elsewhere; the
script reports these rather than inventing a column dosdp would ignore.

Usage:
    blank_level_names.py <repo_root> [--dry-run]
"""
import os
import sys

PREFIX = 'level of '

TARGETS = [
    'entity_attribute_location.tsv',
    'attribute_location_during_activity.tsv',
    'chemical_role_attribute_location.tsv',
    'entity_response_quality_in_location.tsv',
]


def process(path: str, dry_run: bool) -> tuple[int, int, list[str]]:
    with open(path, encoding='utf-8', newline='') as handle:
        text = handle.read()

    had_trailing_newline = text.endswith('\n')
    lines = text.split('\n')
    if had_trailing_newline:
        lines = lines[:-1]

    header = lines[0].split('\t')
    name_idx = header.index('defined_class_name')
    syn_idx = header.index('exact_synonyms') if 'exact_synonyms' in header else None

    blanked = 0
    orphan_synonyms: list[str] = []
    out = [lines[0]]

    for line in lines[1:]:
        fields = line.split('\t')

        # Rows we don't touch are emitted byte-identically: DOSDP TSVs are
        # ragged, and padding them would put trailing tabs on untouched rows.
        if len(fields) <= name_idx or not fields[name_idx].startswith(PREFIX):
            out.append(line)
            continue

        old_label = fields[name_idx]
        fields[name_idx] = ''
        blanked += 1

        if syn_idx is None:
            orphan_synonyms.append(f'{fields[0]}\t{old_label}')
        else:
            # Pad only as far as the synonym column, never to full width.
            if len(fields) <= syn_idx:
                fields += [''] * (syn_idx + 1 - len(fields))
            existing = fields[syn_idx]
            parts = existing.split('|') if existing else []
            if old_label not in parts:
                parts.append(old_label)
            fields[syn_idx] = '|'.join(parts)

        out.append('\t'.join(fields))

    if not dry_run:
        result = '\n'.join(out) + ('\n' if had_trailing_newline else '')
        with open(path, 'w', encoding='utf-8', newline='') as handle:
            handle.write(result)

    return blanked, len(lines) - 1, orphan_synonyms


def main() -> None:
    repo_root = sys.argv[1]
    dry_run = '--dry-run' in sys.argv
    pattern_dir = os.path.join(repo_root, 'src/patterns/data/default')

    total = 0
    all_orphans: list[str] = []
    for name in TARGETS:
        path = os.path.join(pattern_dir, name)
        blanked, rows, orphans = process(path, dry_run)
        total += blanked
        all_orphans.extend(orphans)
        flag = '  [no exact_synonyms column]' if orphans else ''
        print(f'{blanked:>6} / {rows:<6} blanked in {name}{flag}')

    print(f'{total:>6} total rows blanked{" (dry run)" if dry_run else ""}')

    if all_orphans:
        print('\nSynonyms needing another home (no exact_synonyms column):')
        for orphan in all_orphans:
            print(f'  {orphan}')


if __name__ == '__main__':
    main()
