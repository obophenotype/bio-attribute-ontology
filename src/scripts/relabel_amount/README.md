# `level` → `amount` relabel

Scripts used for the one-off relabel of amount traits, so that no OBA label says
"level" and located amount traits share one form, `amount of X in Y`. Kept so
the change is reproducible and auditable; they are not part of any build target.

It ran in two passes. The first relabelled 12,769 traits from `level of X in Y`
to `amount of X in Y`. The second (`relabel_remaining.py`) converted the rest:
2,824 ratios (`level ratio` → `amount ratio`), 215 `X level` labels and 374
`X amount in Y` labels. The synonyms that go with the new labels are not
written here: the entity-first form comes from the location patterns and the
level form from `src/sparql/postprocess-definitions.ru` (see
`docs/editors-guide.md`, "Term label conventions").

These terms are defined against `PATO:0000070` (amount) and their definitions
already read *"The amount of a X when measured in Y"*, but their labels used
`level of …`. The relabel makes labels, definitions and logical axioms agree.
Every relabelled term keeps its former label as an exact synonym.

## Approach

Labels for pattern-generated terms are produced by `dosdp-tools` from the
pattern's `name:` template, **not** from the TSV — the `*_name` columns are
advisory (995 rows have an empty `entity_name` yet still render a full label).
So the effect of a change can only be established by building and comparing,
never by reading the TSV.

The rows needing an explicit `defined_class_name` were therefore discovered
empirically rather than guessed: blank every one, build, diff against the
baseline, and restore explicit names only where the pattern output differs from
the curated label by more than the `level`/`amount` word.

## Order of operations

```sh
S=src/scripts/relabel_amount

# 1. Baseline. The committed definitions.owl is already the baseline - CI
#    regenerates it on every src/patterns/** PR - but verify that first.
python3 $S/extract_labels.py src/patterns/definitions.owl > labels-before.tsv
python3 $S/check_sync.py labels-before.tsv .

# 2. Blank every "level of ..." name; retain the old label as an exact synonym.
python3 $S/blank_level_names.py . --dry-run
python3 $S/blank_level_names.py .

# 3. Rebuild and find the rows the pattern cannot reproduce.
sh $S/build_patterns.sh .
python3 $S/extract_labels.py src/patterns/definitions.owl > labels-after.tsv
python3 $S/compare_labels.py labels-before.tsv labels-after.tsv \
    --write-deviations deviations.tsv
python3 $S/classify_deviations.py deviations.tsv

# 4. Restore explicit names on those rows, hand-edited level -> amount.
python3 $S/restore_deviations.py . deviations.tsv

# 5. Rebuild and verify: every change must be a clean level -> amount swap.
sh $S/build_patterns.sh .
python3 $S/extract_labels.py src/patterns/definitions.owl > labels-final.tsv
python3 $S/compare_labels.py labels-before.tsv labels-final.tsv
python3 $S/verify_synonyms.py labels-before.tsv labels-final.tsv \
    src/patterns/definitions.owl
python3 $S/check_label_synonym_clash.py labels-final.tsv src/patterns/definitions.owl

# 6. Second pass: ratios, "X level" and "X amount in Y" labels. Writes the
#    label each changed row should render to.
python3 $S/relabel_remaining.py . expected-remaining.tsv --dry-run
python3 $S/relabel_remaining.py . expected-remaining.tsv

# 7. Rebuild and verify both passes and the generated synonyms.
sh $S/build_patterns.sh .
python3 $S/verify_remaining.py labels-before.tsv src/patterns/definitions.owl \
    expected-remaining.tsv

# 8. Stale labels in the SSSOM mapping files, which are Google-Sheets-synced
#    and so cannot be fixed in this repo.
python3 $S/extract_labels.py src/patterns/definitions.owl > labels-final.tsv
python3 $S/mapping_handoff.py . labels-final.tsv --before labels-before.tsv \
    > mapping-handoff.tsv
```

`build_patterns.sh` mirrors `src/ontology/run.sh` without the `-ti` flags it
hardcodes, and uses the ODK image pinned in `src/ontology/run.sh.conf` (v1.6),
as `.github/workflows/dosdp.yml` does. Before relying on the comparison, the
local image was confirmed to reproduce master's committed `definitions.owl`
byte-for-byte.

Master refreshed its imports after the first pass, and PRO had renamed 69 of
the entities behind blanked rows (e.g. "smad4" is now "SMAD family member 4").
Those rows were given explicit names too, so that the first pass still changes
exactly one word per label; they are the extra rows in `deviations.tsv`.

## Result

First pass, re-verified after merging master:

```
labels changed:        12769
  clean level->amount: 12769
  deviations:              0
  unexpected:              0
terms added / removed:   0 / 0
still "level of ...":      0
NEW duplicate labels:      0
old label retained as synonym: 12769 / 12769
synonym == some term label:        0
```

Both passes and the generated synonyms (`verify_remaining.py`):

```
labels changed:                  16180
  first pass (level of -> amount of): 12769
  second pass, as expected:       3411
problems:                        0
labels still containing "level": 0
relabelled without old label as synonym: 0
amount traits:                   15477
  "amount of X in Y" without entity-first synonym: 0
  "amount" label without a level synonym:          0
"/generated" markers left:       0
exact synonyms shared by >1 term (ignoring case): 0
synonyms equal to another term's label:          3
```

The three synonyms that equal another term's label were already there on master
(e.g. OBA:2060174 `amount of insulin in blood` has the pattern synonym
`blood insulin amount`, the label of OBA:VT0001560).

## Records

- `deviations.tsv` — the 334 first-pass rows that kept an explicit name, with
  the curated label, the pattern's output, and the label applied.
- `entity-renamed-237.txt` — the subset whose curated label uses a different name
  for the entity than the entity's own ontology label. Left as-is here; needs
  curatorial review of its own.
- `mapping-handoff.tsv` — the 112 labels in `src/mappings/*.sssom.tsv` made
  stale by the relabel (67 EFO, 45 LOINC), for the owner of the source Google
  Sheets. Mapping IDs are unaffected.
