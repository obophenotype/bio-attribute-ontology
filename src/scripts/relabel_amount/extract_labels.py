#!/usr/bin/env python3
"""Extract OBA class labels from a DOSDP-generated OWL functional-syntax file.

Usage:
    extract_labels.py <definitions.ofn|definitions.owl> > labels.tsv

Output: two columns, `OBA:xxxxxxx<TAB>label`, sorted by ID.

Used to build the "before" and "after" label sets for the level->amount
relabel, so the two can be diffed term-by-term.
"""
import re
import sys

# AnnotationAssertion(rdfs:label <http://purl.obolibrary.org/obo/OBA_2045560> "amount of iron in brain")
# The literal may carry a ^^xsd:string type tag (dosdp-tools emits it; ROBOT strips it).
LABEL_RE = re.compile(
    r'AnnotationAssertion\(rdfs:label\s+'
    r'<http://purl\.obolibrary\.org/obo/(OBA)_([^>]+)>\s+'
    r'"((?:[^"\\]|\\.)*)"'
)


def unescape(literal: str) -> str:
    return literal.replace('\\"', '"').replace('\\\\', '\\')


def main() -> None:
    path = sys.argv[1]
    labels: dict[str, str] = {}
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            match = LABEL_RE.search(line)
            if match:
                curie = f'{match.group(1)}:{match.group(2)}'
                labels[curie] = unescape(match.group(3))

    for curie in sorted(labels):
        print(f'{curie}\t{labels[curie]}')

    print(f'{len(labels)} OBA labels extracted from {path}', file=sys.stderr)


if __name__ == '__main__':
    main()
