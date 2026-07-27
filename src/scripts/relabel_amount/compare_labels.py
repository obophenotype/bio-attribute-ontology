#!/usr/bin/env python3
"""Compare the before/after label sets of the level->amount relabel.

Classifies every changed label into:

  clean      - differs from the old label only by the leading "level"/"amount"
               word. This is the intended change and needs no explicit name.
  deviation  - changed in some other way too, i.e. the curated label carried
               information the pattern does not reproduce (a suppressed
               location, parenthesised lipid notation, a different word order).
               These rows need their explicit `defined_class_name` restored,
               hand-edited to "amount of ...".
  unexpected - a label changed on a term that was not a `level of ...` term.
               Should be empty.

Also reports terms that gained or lost a label, and any duplicate labels
introduced by the change (two IDs collapsing onto one string).

Usage:
    compare_labels.py <labels-before.tsv> <labels-after.tsv> [--write-deviations <path>]
"""
import sys


def load(path: str) -> dict[str, str]:
    labels = {}
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            curie, _, label = line.rstrip('\n').partition('\t')
            labels[curie] = label
    return labels


def main() -> None:
    before = load(sys.argv[1])
    after = load(sys.argv[2])

    write_path = None
    if '--write-deviations' in sys.argv:
        write_path = sys.argv[sys.argv.index('--write-deviations') + 1]

    added = sorted(set(after) - set(before))
    removed = sorted(set(before) - set(after))
    changed = sorted(c for c in set(before) & set(after) if before[c] != after[c])

    clean, deviations, unexpected = [], [], []
    for curie in changed:
        old, new = before[curie], after[curie]
        if not old.startswith('level of '):
            unexpected.append((curie, old, new))
        elif 'amount of ' + old[len('level of '):] == new:
            clean.append((curie, old, new))
        else:
            deviations.append((curie, old, new))

    stale = sorted(c for c in set(before) & set(after)
                   if before[c] == after[c] and before[c].startswith('level of '))

    print(f'terms before:         {len(before)}')
    print(f'terms after:          {len(after)}')
    print(f'labels changed:       {len(changed)}')
    print(f'  clean level->amount:{len(clean):>6}')
    print(f'  deviations:         {len(deviations):>6}')
    print(f'  unexpected:         {len(unexpected):>6}')
    print(f'terms added:          {len(added)}')
    print(f'terms removed:        {len(removed)}')
    print(f'still "level of ...": {len(stale)}')

    # Duplicate labels are the real hazard: two IDs collapsing onto one string.
    seen: dict[str, list[str]] = {}
    for curie, label in after.items():
        seen.setdefault(label, []).append(curie)
    dupes_after = {l: c for l, c in seen.items() if len(c) > 1}

    seen_before: dict[str, list[str]] = {}
    for curie, label in before.items():
        seen_before.setdefault(label, []).append(curie)
    dupes_before = {l: c for l, c in seen_before.items() if len(c) > 1}

    new_dupes = {l: c for l, c in dupes_after.items() if l not in dupes_before}
    print(f'duplicate labels before: {len(dupes_before)}')
    print(f'duplicate labels after:  {len(dupes_after)}')
    print(f'NEW duplicate labels:    {len(new_dupes)}')
    for label, curies in sorted(new_dupes.items())[:20]:
        print(f'  {label!r}  <- {", ".join(sorted(curies))}')

    if unexpected:
        print('\nUNEXPECTED changes:')
        for curie, old, new in unexpected[:20]:
            print(f'  {curie}\n    was: {old!r}\n    now: {new!r}')

    if deviations:
        print(f'\nDEVIATIONS ({len(deviations)}) - need explicit names restored:')
        for curie, old, new in deviations[:40]:
            print(f'  {curie}\n    was: {old!r}\n    now: {new!r}')
        if len(deviations) > 40:
            print(f'  ... and {len(deviations) - 40} more')

    if write_path:
        with open(write_path, 'w', encoding='utf-8') as handle:
            for curie, old, new in deviations:
                intended = 'amount of ' + old[len('level of '):]
                handle.write(f'{curie}\t{old}\t{new}\t{intended}\n')
        print(f'\ndeviations written to {write_path}')


if __name__ == '__main__':
    main()
