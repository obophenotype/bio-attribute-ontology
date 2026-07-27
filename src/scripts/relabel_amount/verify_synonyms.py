#!/usr/bin/env python3
"""Verify every relabeled term kept its old `level of ...` label as an exact synonym.

For each term whose label changed from "level of X" to "amount of X", assert
that the built OWL still carries the old string as an oboInOwl:hasExactSynonym.
A term missing it would have silently lost its old name to downstream lookup.

Usage:
    verify_synonyms.py <labels-before.tsv> <labels-after.tsv> <definitions.owl>
"""
import re
import sys
from collections import defaultdict

SYN_RE = re.compile(
    r'hasExactSynonym>\s+<http://purl\.obolibrary\.org/obo/(OBA)_([^>]+)>\s+'
    r'"((?:[^"\\]|\\.)*)"'
)


def load(path: str) -> dict[str, str]:
    labels = {}
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            curie, _, label = line.rstrip('\n').partition('\t')
            labels[curie] = label
    return labels


def main() -> None:
    before, after, owl_path = load(sys.argv[1]), load(sys.argv[2]), sys.argv[3]

    synonyms = defaultdict(set)
    with open(owl_path, encoding='utf-8') as handle:
        for line in handle:
            match = SYN_RE.search(line)
            if match:
                curie = f'{match.group(1)}:{match.group(2)}'
                synonyms[curie].add(match.group(3).replace('\\"', '"'))

    relabeled = [c for c in before
                 if c in after
                 and before[c].startswith('level of ')
                 and after[c].startswith('amount of ')]

    missing = [c for c in relabeled if before[c] not in synonyms[c]]

    print(f'relabeled terms:              {len(relabeled)}')
    print(f'old label retained as synonym:{len(relabeled) - len(missing):>6}')
    print(f'MISSING synonym:              {len(missing):>6}')
    for curie in sorted(missing):
        print(f'  {curie}')
        print(f'    old label : {before[curie]!r}')
        print(f'    new label : {after[curie]!r}')
        print(f'    synonyms  : {sorted(synonyms[curie])}')


if __name__ == '__main__':
    main()
