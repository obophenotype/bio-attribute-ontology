#!/usr/bin/env python3
"""Verify the second relabel pass and the generated synonyms.

Compares the labels in a freshly built definitions.owl against a baseline and
checks that:

  - every changed label is either a clean "level of" -> "amount of" swap from
    the first pass or exactly the label relabel_remaining.py expected;
  - no pattern label still contains the word "level";
  - every relabelled term kept its former label as an exact synonym, except
    where that former label is its generated entity-first synonym;
  - amount traits labelled "amount of X in Y" carry an entity-first synonym
    ("X amount in Y"), and every amount trait carries a "level" synonym;
  - no exact synonym is shared by two terms (case-insensitive, as ROBOT's
    duplicate_exact_synonym check does) and no synonym is another term's label.

Usage:
    verify_remaining.py <labels-before.tsv> <definitions.owl> <expected-labels.tsv>
"""
import collections
import re
import sys

OBO = 'http://purl.obolibrary.org/obo/'
LEVEL = re.compile(r'\blevels?\b', re.IGNORECASE)
ANNOT = re.compile(r'^AnnotationAssertion\((?:Annotation\(<http://www\.geneontology\.org/formats/'
                   r'oboInOwl#hasDbXref> "([^"]*)"\) )?(rdfs:label|<[^>]+>) <([^>]+)> "((?:[^"\\]|\\.)*)"')
GENUS = re.compile(r'^EquivalentClasses\(<http://purl\.obolibrary\.org/obo/(OBA_\w+)> '
                   r'ObjectIntersectionOf\(<http://purl\.obolibrary\.org/obo/(\w+)>')


def curie(iri: str) -> str:
    return iri[len(OBO):].replace('_', ':', 1) if iri.startswith(OBO) else iri


def unescape(value: str) -> str:
    return value.replace('\\"', '"').replace('\\\\', '\\')


def load_tsv(path: str) -> dict[str, str]:
    with open(path, encoding='utf-8') as handle:
        return dict(line.rstrip('\n').split('\t', 1) for line in handle if '\t' in line)


def main() -> None:
    before = load_tsv(sys.argv[1])
    expected = load_tsv(sys.argv[3])
    labels: dict[str, str] = {}
    exact: dict[str, list[tuple[str, str]]] = collections.defaultdict(list)
    genus: dict[str, str] = {}
    with open(sys.argv[2], encoding='utf-8') as handle:
        for line in handle:
            if line.startswith('AnnotationAssertion('):
                match = ANNOT.match(line)
                if not match:
                    continue
                xref, prop, subject, value = match.groups()
                cid, value = curie(subject), unescape(value)
                if prop == 'rdfs:label':
                    labels[cid] = value
                elif prop.endswith('#hasExactSynonym>'):
                    exact[cid].append((value, xref or ''))
            elif line.startswith('EquivalentClasses('):
                match = GENUS.match(line)
                if match:
                    genus[curie(OBO + match.group(1))] = curie(OBO + match.group(2))

    problems = []
    changed = {c for c in labels if c in before and labels[c] != before[c]}
    first_pass = {c for c in changed
                  if before[c].startswith('level of ') and labels[c] == 'amount of ' + before[c][9:]}
    second_pass = changed - first_pass
    for c in sorted(second_pass):
        if expected.get(c) != labels[c]:
            problems.append(f'unexpected label change {c}: {before[c]!r} -> {labels[c]!r}'
                            f' (expected {expected.get(c)!r})')
    for c, want in sorted(expected.items()):
        if c in labels and labels[c] != want:
            problems.append(f'{c}: expected {want!r}, built {labels[c]!r}')
    if set(labels) != set(before):
        problems.append(f'terms added {sorted(set(labels) - set(before))[:5]} '
                        f'removed {sorted(set(before) - set(labels))[:5]}')

    still_level = sorted(c for c, l in labels.items() if LEVEL.search(l))

    lost = []
    for c in sorted(changed):
        synonyms = {s for s, _ in exact[c]}
        old = re.sub(r'\s+', ' ', before[c]).strip()
        if old not in synonyms:
            lost.append(c)

    amount = [c for c, g in genus.items() if g == 'PATO:0000070' and c in labels]
    no_entity_first = [c for c in amount
                       if labels[c].startswith('amount of ') and ' in ' in labels[c]
                       and not any(re.search(r' amount in ', s) for s, _ in exact[c])]
    no_level = [c for c in amount if re.search(r'\bamount\b', labels[c])
                and not any(LEVEL.search(s) for s, _ in exact[c])]
    marker_left = sum(1 for c in exact for _, x in exact[c] if x.endswith('/generated'))

    owners: dict[str, set[str]] = collections.defaultdict(set)
    for c, syns in exact.items():
        for s, _ in syns:
            owners[s.upper()].add(c)
    shared = {k: v for k, v in owners.items() if len(v) > 1}
    label_owner = {l.upper(): c for c, l in labels.items()}
    syn_is_other_label = sorted({(c, s) for c, syns in exact.items() for s, _ in syns
                                 if label_owner.get(s.upper(), c) != c})

    print(f'labels changed:                  {len(changed)}')
    print(f'  first pass (level of -> amount of): {len(first_pass)}')
    print(f'  second pass, as expected:       {len(second_pass) - sum(1 for p in problems if p.startswith("unexpected"))}')
    print(f'problems:                        {len(problems)}')
    print(f'labels still containing "level": {len(still_level)}')
    print(f'relabelled without old label as synonym: {len(lost)}')
    print(f'amount traits:                   {len(amount)}')
    print(f'  "amount of X in Y" without entity-first synonym: {len(no_entity_first)}')
    print(f'  "amount" label without a level synonym:          {len(no_level)}')
    print(f'"/generated" markers left:       {marker_left}')
    print(f'exact synonyms shared by >1 term (ignoring case): {len(shared)}')
    print(f'synonyms equal to another term\'s label:          {len(syn_is_other_label)}')
    for label, items in (('PROBLEMS', problems), ('STILL LEVEL', still_level), ('LOST OLD LABEL', lost),
                         ('NO ENTITY-FIRST', no_entity_first), ('NO LEVEL SYNONYM', no_level),
                         ('SHARED', sorted(shared.items())[:10]), ('SYNONYM = OTHER LABEL', syn_is_other_label)):
        if items:
            print(f'\n{label} ({len(items)}):')
            for item in list(items)[:10]:
                if isinstance(item, str) and item in labels:
                    print(f'  {item}\t{labels[item]}')
                else:
                    print(f'  {item}')


if __name__ == '__main__':
    main()
