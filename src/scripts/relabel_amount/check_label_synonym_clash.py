#!/usr/bin/env python3
"""Check the retained `level of ...` synonyms against every term label.

ROBOT report flags a synonym that duplicates a label on a *different* term
(duplicate_label_synonym). Since the relabel adds ~12,769 synonyms at once,
this checks that none of them collides with any label in the built ontology,
and that no two terms ended up sharing one of the added synonyms.

Usage:
    check_label_synonym_clash.py <labels-after.tsv> <definitions.owl>
"""
import re
import sys
from collections import defaultdict

SYN_RE = re.compile(
    r'hasExactSynonym>\s+<http://purl\.obolibrary\.org/obo/(OBA)_([^>]+)>\s+'
    r'"((?:[^"\\]|\\.)*)"'
)


def main() -> None:
    labels_path, owl_path = sys.argv[1], sys.argv[2]

    label_of = {}
    term_with_label = defaultdict(list)
    with open(labels_path, encoding='utf-8') as handle:
        for line in handle:
            curie, _, label = line.rstrip('\n').partition('\t')
            label_of[curie] = label
            term_with_label[label].append(curie)

    added_synonym_owners = defaultdict(list)
    with open(owl_path, encoding='utf-8') as handle:
        for line in handle:
            match = SYN_RE.search(line)
            if not match:
                continue
            curie = f'{match.group(1)}:{match.group(2)}'
            synonym = match.group(3).replace('\\"', '"')
            if synonym.startswith('level of '):
                added_synonym_owners[synonym].append(curie)

    clashes = []
    for synonym, owners in added_synonym_owners.items():
        for other in term_with_label.get(synonym, []):
            clashes.append((synonym, owners, other))

    shared = {s: o for s, o in added_synonym_owners.items() if len(set(o)) > 1}

    print(f'retained "level of ..." synonyms: {len(added_synonym_owners)}')
    print(f'synonym == some term label:       {len(clashes)}')
    print(f'same synonym on >1 term:          {len(shared)}')

    for synonym, owners, other in clashes[:20]:
        print(f'  CLASH {synonym!r} is a synonym of {owners} and the label of {other}')
    for synonym, owners in list(shared.items())[:20]:
        print(f'  SHARED {synonym!r} -> {sorted(set(owners))}')


if __name__ == '__main__':
    main()
