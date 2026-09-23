#!/usr/bin/env python3
"""Second pass of the level -> amount relabel: the labels the first pass left.

The first pass (blank_level_names.py / restore_deviations.py) converted every
`level of X in Y` label. This pass converts the rest, so that no pattern label
says "level" any more and the located amount terms share one form:

  1. attribute_ratio.tsv      "<A>/<B> protein level ratio in blood"
                              -> "<A>/<B> protein amount ratio in blood"
  2. "X level" labels         -> "amount of X [in Y]" in the location patterns
                                 (entity_attribute_location,
                                 chemical_role_attribute_location);
                              -> "X amount" in the entity-first patterns
                                 (entity_attribute, chemical_role_attribute),
                                 whose name template is "%s %s".
  3. "X amount in Y" labels   -> "amount of X in Y" (entity_attribute_location).

A row whose new label the pattern renders by itself gets an empty name; every
other row gets an explicit name that keeps the curated wording of the entity
and changes only the level/amount word and, where needed, the word order.
Rows whose attribute is not an amount, and rows that need a curator's wording,
are listed in HAND_EDITED below.

Every relabelled row keeps its former label (whitespace-normalised) as an exact
synonym, except where the former label is exactly the entity-first synonym the
pattern now generates itself ("X amount in Y"), which would only duplicate it.

Writes the label each changed row is expected to render to, so the build can
be checked against it (see README).

Usage:
    relabel_remaining.py <repo_root> <expected-labels.tsv> [--dry-run]
"""
import csv
import json
import os
import re
import sys

LEVEL = re.compile(r'\blevels?\b', re.IGNORECASE)
PLACEHOLDER = 'UBERON:0001062'  # 'anatomical entity', used when there is no location
AMOUNT = 'PATO:0000070'

# Rows that cannot be converted mechanically: the curated label carries a
# location adjective ("serum ...", "erythrocyte ..."), a different name for the
# entity than its ontology label, or the attribute is not an amount at all.
# '' means the pattern's own rendering is the right label.
HAND_EDITED = {
    # entity_attribute_location, located "X level" labels
    'OBA:0000016': 'amount of angiotensin in blood',
    'OBA:2045313': '',
    'OBA:2045314': '',
    'OBA:2045316': 'amount of cadmium in erythrocyte',
    'OBA:2045317': '',
    'OBA:2045318': 'cerebral blood flow rate',  # attribute is PATO:0002243 fluid flow rate
    'OBA:2045319': 'amount of gamma-glutamyl transferase in blood serum',
    'OBA:2045321': 'amount of carcinoembryonic antigen in blood serum',
    'OBA:2045323': 'amount of copper in blood',
    'OBA:2045374': 'amount of serotonin transporter in brain',
    'OBA:2045375': 'amount of cell free DNA in blood',
    'OBA:2045376': 'amount of copper in blood serum',
    'OBA:2045395': 'amount of sodium in blood serum',
    'OBA:2045396': '',
    'OBA:2045397': '',
    'OBA:2045398': '',
    'OBA:2045442': 'amount of oxygen in arterial blood',
    'OBA:2045449': '',
    'OBA:VT0001905': '',
    'OBA:2055808': '',
    'OBA:2055809': '',
    # entity_attribute ("%s %s", entity first)
    'OBA:0000036': 'body fluid volume',  # attribute is PATO:0000918 volume
    'OBA:0000061': 'circulating fibrinogen amount',
    'OBA:2045225': 'blood clotting amount',
    'OBA:2045372': 'gestational blood glucose amount',  # attribute is OBA:VT0000188
}


def norm(text: str) -> str:
    return re.sub(r'\s+', ' ', text).strip()


def load_labels(repo_root: str) -> dict[str, str]:
    """rdfs:label of every class in the merged import, keyed by CURIE."""
    rx = re.compile(r'^AnnotationAssertion\((?:Annotation\(.*?\) )*rdfs:label '
                    r'<http://purl\.obolibrary\.org/obo/([A-Za-z]+)_([^>]+)> "((?:[^"\\]|\\.)*)"')
    labels = {}
    path = os.path.join(repo_root, 'src/ontology/imports/merged_import.owl')
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            if line.startswith('AnnotationAssertion('):
                match = rx.match(line)
                if match:
                    value = match.group(3).replace('\\"', '"').replace('\\\\', '\\')
                    labels[f'{match.group(1)}:{match.group(2)}'] = value
    return labels


class Table:
    """A pattern TSV edited in place, preserving everything but the cells changed."""

    def __init__(self, path: str):
        self.path = path
        with open(path, encoding='utf-8', newline='') as handle:
            text = handle.read()
        self.trailing_newline = text.endswith('\n')
        lines = text.split('\n')
        if self.trailing_newline:
            lines = lines[:-1]
        self.header = lines[0].split('\t')
        self.rows = [line.split('\t') for line in lines[1:]]

    def col(self, name: str) -> int:
        return self.header.index(name)

    def ensure_column(self, name: str) -> int:
        if name not in self.header:
            self.header.append(name)
        return self.col(name)

    def get(self, row: list[str], name: str) -> str:
        idx = self.col(name)
        return row[idx] if idx < len(row) else ''

    def set(self, row: list[str], name: str, value: str) -> None:
        idx = self.col(name)
        while len(row) <= idx:
            row.append('')
        row[idx] = value

    def add_synonym(self, row: list[str], synonym: str, label: str) -> None:
        idx = self.ensure_column('exact_synonyms')
        while len(row) <= idx:
            row.append('')
        current = [norm(s) for s in row[idx].split('|') if s.strip()]
        if synonym and synonym != label and synonym not in current:
            current.append(synonym)
        row[idx] = '|'.join(current)

    def write(self) -> None:
        out = ['\t'.join(self.header)] + ['\t'.join(row) for row in self.rows]
        text = '\n'.join(out) + ('\n' if self.trailing_newline else '')
        with open(self.path, 'w', encoding='utf-8', newline='') as handle:
            handle.write(text)


def main() -> None:
    repo_root, expected_path = sys.argv[1], sys.argv[2]
    dry_run = '--dry-run' in sys.argv
    labels = load_labels(repo_root)
    pattern_dir = os.path.join(repo_root, 'src/patterns/data/default')
    expected: dict[str, str] = {}
    counts: dict[str, int] = {}

    def done(group: str, curie: str, label: str) -> None:
        expected[curie] = label
        counts[group] = counts.get(group, 0) + 1

    # 1. ratios
    ratio = Table(os.path.join(pattern_dir, 'attribute_ratio.tsv'))
    for row in ratio.rows:
        name = ratio.get(row, 'defined_class_name')
        if LEVEL.search(name):
            old = norm(name)
            new = norm(LEVEL.sub('amount', name, count=1))
            ratio.set(row, 'defined_class_name', new)
            ratio.add_synonym(row, old, new)
            done('attribute_ratio: level ratio -> amount ratio', row[0], new)

    # 2 + 3. entity_attribute_location
    eal = Table(os.path.join(pattern_dir, 'entity_attribute_location.tsv'))
    for row in eal.rows:
        curie, name = row[0], eal.get(row, 'defined_class_name')
        if not name.strip() or re.search(r'\bratio\b', name):
            continue
        entity = labels.get(eal.get(row, 'entity'), '')
        location = labels.get(eal.get(row, 'location'), '')
        rendered = f'amount of {entity} in {location}'
        entity_first = f'{entity} amount in {location}'
        old = norm(name)
        if LEVEL.search(name) and not re.match(r'levels? of ', name, re.IGNORECASE):
            if curie in HAND_EDITED:
                new = HAND_EDITED[curie]
                group = 'entity_attribute_location: located X level (hand-edited)'
            elif eal.get(row, 'location') == PLACEHOLDER:
                new = 'amount of ' + norm(LEVEL.sub('', name))
                group = 'entity_attribute_location: X level -> amount of X'
            else:
                raise SystemExit(f'{curie}: located "X level" row not in HAND_EDITED: {name!r}')
            eal.set(row, 'defined_class_name', new)
            eal.add_synonym(row, old, new or rendered)
            done(group, curie, new or rendered)
        elif re.search(r'\bamounts? in ', name) and eal.get(row, 'attribute') == AMOUNT:
            thing, _, where = norm(name).rpartition(' amount in ')
            if not thing or not where:
                raise SystemExit(f'{curie}: cannot split {name!r} on " amount in "')
            new = f'amount of {thing} in {where}'
            explicit = '' if new == rendered else new
            eal.set(row, 'defined_class_name', explicit)
            if old != entity_first:
                eal.add_synonym(row, old, new)
            done('entity_attribute_location: X amount in Y -> amount of X in Y'
                 + (' (explicit)' if explicit else ' (pattern)'), curie, new)

    # A stray trailing-whitespace synonym flagged in review.
    for row in eal.rows:
        cell = eal.get(row, 'exact_synonyms')
        if cell and cell != '|'.join(norm(s) for s in cell.split('|')):
            eal.set(row, 'exact_synonyms', '|'.join(norm(s) for s in cell.split('|')))
            counts['entity_attribute_location: synonym whitespace normalised'] = \
                counts.get('entity_attribute_location: synonym whitespace normalised', 0) + 1

    # 2. chemical_role_attribute_location ("%s of %s in %s")
    cral = Table(os.path.join(pattern_dir, 'chemical_role_attribute_location.tsv'))
    for row in cral.rows:
        name = cral.get(row, 'defined_class_name')
        if LEVEL.search(name):
            role = labels.get(cral.get(row, 'role'), '')
            location = labels.get(cral.get(row, 'location'), '')
            cral.set(row, 'defined_class_name', '')
            new = f'amount of {role} in {location}'
            cral.add_synonym(row, norm(name), new)
            done('chemical_role_attribute_location: X level -> amount of X in Y', row[0], new)

    # 2. entity-first patterns ("%s %s")
    ea = Table(os.path.join(pattern_dir, 'entity_attribute.tsv'))
    for row in ea.rows:
        name = ea.get(row, 'defined_class_name')
        if LEVEL.search(name) and not re.search(r'\bratio\b', name):
            new = HAND_EDITED[row[0]]
            ea.set(row, 'defined_class_name', new)
            ea.add_synonym(row, norm(name), new)
            done('entity_attribute: X level -> X amount (hand-edited)', row[0], new)

    cra = Table(os.path.join(pattern_dir, 'chemical_role_attribute.tsv'))
    cra.ensure_column('exact_synonyms')
    for row in cra.rows:
        name = cra.get(row, 'defined_class_name')
        if LEVEL.search(name):
            role = labels.get(cra.get(row, 'role'), '')
            new = f'{role} amount'
            cra.set(row, 'defined_class_name', '')
            cra.add_synonym(row, norm(name), new)
            done('chemical_role_attribute: X level -> X amount', row[0], new)

    for group, count in sorted(counts.items()):
        print(f'{count:>6}  {group}')
    print(f'{len(expected):>6}  labels changed in total')

    if not dry_run:
        for table in (ratio, eal, cral, ea, cra):
            table.write()
        with open(expected_path, 'w', encoding='utf-8') as handle:
            for curie, label in sorted(expected.items()):
                handle.write(f'{curie}\t{label}\n')


if __name__ == '__main__':
    main()
