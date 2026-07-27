#!/usr/bin/env python3
"""Bucket the deviations by *why* the pattern output differs from the curated label.

Input is deviations.tsv from compare_labels.py:
    OBA:id <TAB> old label <TAB> new (pattern) label <TAB> intended level->amount label

Buckets:
  location-suppressed - curated label omitted the trailing "in <location>"
  notation            - same words, differing punctuation/case (e.g. "(56:6)" vs "56:6")
  entity-renamed      - the entity term itself differs: the curated label used a
                        different name for the entity than its current ontology
                        label (usually an older or alternative protein name)
  other               - anything the above don't explain

Usage:
    classify_deviations.py <deviations.tsv> [--bucket <name>] [--limit N]
"""
import re
import sys
from collections import defaultdict


def normalise(text: str) -> str:
    """Strip punctuation and case so notation-only differences collapse."""
    return re.sub(r'[^a-z0-9]+', '', text.lower())


def main() -> None:
    path = sys.argv[1]
    want = None
    if '--bucket' in sys.argv:
        want = sys.argv[sys.argv.index('--bucket') + 1]
    limit = int(sys.argv[sys.argv.index('--limit') + 1]) if '--limit' in sys.argv else 15

    buckets = defaultdict(list)

    with open(path, encoding='utf-8') as handle:
        for line in handle:
            curie, old, new, intended = line.rstrip('\n').split('\t')
            old_rest = old[len('level of '):]
            new_rest = new[len('amount of '):]

            if new_rest.startswith(old_rest + ' in '):
                bucket = 'location-suppressed'
            elif normalise(old_rest) == normalise(new_rest):
                bucket = 'notation'
            else:
                # Compare only the part before " in <location>", so a differing
                # entity term is distinguished from a differing location.
                old_entity = old_rest.rsplit(' in ', 1)[0]
                new_entity = new_rest.rsplit(' in ', 1)[0]
                if normalise(old_entity) != normalise(new_entity):
                    bucket = 'entity-renamed'
                else:
                    bucket = 'other'

            buckets[bucket].append((curie, old, new, intended))

    total = sum(len(v) for v in buckets.values())
    print(f'{total} deviations\n')
    for name in ('entity-renamed', 'location-suppressed', 'notation', 'other'):
        print(f'  {name:<22} {len(buckets[name])}')

    for name in ([want] if want else ('location-suppressed', 'notation', 'other', 'entity-renamed')):
        rows = buckets[name]
        if not rows:
            continue
        print(f'\n=== {name} ({len(rows)}) ===')
        for curie, old, new, intended in rows[:limit]:
            print(f'  {curie}')
            print(f'    curated : {old}')
            print(f'    pattern : {new}')
        if len(rows) > limit:
            print(f'  ... and {len(rows) - limit} more')


if __name__ == '__main__':
    main()
