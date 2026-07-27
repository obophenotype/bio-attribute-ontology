#!/usr/bin/env python3
"""Produce the hand-off list of stale OBA labels in the SSSOM mapping files.

src/mappings/*.sssom.tsv are wget-synced from published Google Sheets
(see src/ontology/oba.Makefile), so their `object_label` column cannot be
durably fixed in this repo. This lists the rows whose OBA label changed, for
whoever maintains the sheets. Mapping IDs are unaffected - only the
human-readable label column goes stale.

Usage:
    mapping_handoff.py <repo_root> <labels-after.tsv>
"""
import csv
import glob
import os
import sys


def main() -> None:
    repo_root, labels_path = sys.argv[1], sys.argv[2]

    new_labels = {}
    with open(labels_path, encoding='utf-8') as handle:
        for line in handle:
            curie, _, label = line.rstrip('\n').partition('\t')
            new_labels[curie] = label

    rows = []
    for path in sorted(glob.glob(os.path.join(repo_root, 'src/mappings/*.sssom.tsv'))):
        with open(path, encoding='utf-8', newline='') as handle:
            # SSSOM files carry '#' YAML preamble before the TSV header.
            lines = [l for l in handle if not l.startswith('#')]
        reader = csv.DictReader(lines, delimiter='\t')
        if 'object_id' not in (reader.fieldnames or []):
            continue
        for row in reader:
            object_id = (row.get('object_id') or '').strip()
            old = (row.get('object_label') or '').strip()
            if not old.startswith('level of '):
                continue
            rows.append((
                os.path.basename(path),
                (row.get('subject_id') or '').strip(),
                object_id,
                old,
                new_labels.get(object_id, '?? not found'),
            ))

    print('file\tsubject_id\tobject_id\told_object_label\tnew_object_label')
    for row in rows:
        print('\t'.join(row))
    print(f'\n{len(rows)} rows need object_label updated in the source Google Sheets',
          file=sys.stderr)


if __name__ == '__main__':
    main()
