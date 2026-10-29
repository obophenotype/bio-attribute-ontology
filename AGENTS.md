# Ontology of Biological Attributes (OBA): agent guide

Instructions for AI agents editing OBA. Human-facing workflows are in `docs/editors-guide.md`; read the relevant section there before doing anything it covers.

## Where things live

- **Pattern terms (most of OBA)**: rows in `src/patterns/data/default/*.tsv`, one TSV per DOSDP pattern in `src/patterns/dosdp-patterns/*.yaml`.
- **Hand-edited terms**: `src/ontology/oba-edit.obo`.
- **Obsoletions**: `src/templates/obsoletes.tsv` (ROBOT template, built into `src/ontology/components/obsoletes.owl`).
- **Generated, never edit by hand**: `src/patterns/definitions.owl`, `src/ontology/imports/*_import.owl`, `src/ontology/components/*.owl`, and the release files in the repo root.
- **Mappings synced from Google Sheets, never edit in the repo**: `src/mappings/oba-efo.sssom.tsv`, `oba-vt.sssom.tsv`, `oba-loinc.sssom.tsv` and their `*-exclusions` files (see `OBA_*_GS` in `src/ontology/oba.Makefile`). Propose mapping rows for a curator to paste into the sheet instead.
- **ID ranges**: `src/ontology/oba-idranges.owl`. Agent work uses idrange:13, `OBA:2100000`–`OBA:2109999`.

## Finding terms

- Look up an existing term by ID in `src/patterns/definitions.owl` (OWL functional syntax): `grep 'OBA_2040177>' src/patterns/definitions.owl`.
- Look up which TSV row defines it: `grep -rn 'OBA:2040177' src/patterns/data/default/`.
- Before minting, check for an existing class with the **same filler and attribute** (in any pattern TSV, not only the one you are editing) and for label/synonym clashes.
- Never guess OBA IDs, filler IDs or PMIDs. Look filler terms up in OLS.

## Creating terms

1. Read the issue and any linked issues (`gh issue view N --json title,body,comments`). If a PMID is cited, read it.
2. Pick the pattern and fillers. Follow how existing terms of the same kind are modelled:
   - Amount of a chemical or protein in a location: `entity_attribute_location.tsv` with `PATO:0000070` amount, e.g. cholesterol + amount + blood serum. Leave `defined_class_name` empty: the pattern labels it `amount of cholesterol in blood serum` and generates the `cholesterol amount in blood serum` and `level of cholesterol in blood serum` synonyms.
   - Disease onset: `disease_onset.tsv`. Response to a chemical: `response_to_chemical_stimulus_trait.tsv`.
   - GO cellular component morphology and GO process traits: `entity_attribute_part_of.tsv` with `PATO:0000051` morphology or `PATO:0000001` quality. That pattern uses `characteristic_of_part_of` and is for morphology and quality only.
   - Position and other specific attributes: `entity_attribute.tsv` (`characteristic_of`).
3. Conventions:
   - **Never use "level" in a label** (`level-in-label-violation.sparql`; see "Term label conventions" in `docs/editors-guide.md`). Use "amount of X in Y" / "X amount".
   - Prefer leaving `defined_class_name` empty so the pattern generates the label.
   - Use **species-neutral** PRO fillers (`PR:000…`, "translation product of the human X gene or a 1:1 ortholog thereof"), not `(human)` UniProt classes.
   - Amounts in body fluids: mint **blood-level** classes only, not separate serum/plasma classes, unless there is a concrete need for the split. Map serum/plasma measurements to the blood class.
4. Pick IDs in idrange:13 after the highest one used on `master` **and** in open PRs (`gh pr list`, then check their diffs). Concurrent PRs have collided before.
5. Check every filler is imported: `grep -c 'PR_000001393>' src/ontology/imports/merged_import.owl`. PRO and ChEBI come from slims (https://github.com/obophenotype/pro_obo_slim, https://github.com/obophenotype/chebi_obo_slim); if a filler is missing from the slim mirror, say so on the issue rather than working around it.
6. Regenerate and test (see "Running ODK" below).

## Obsoleting terms

- Delete the row from the pattern TSV (or the term from `oba-edit.obo`, leaving a bare `id:` stub).
- Add a row to `src/templates/obsoletes.tsv`: IRI, `owl:Class`, `true`, replacement IRI (if any), label `obsolete <last label>`, and a comment starting `Reason for obsoletion: ` that links the issue. Every obsolete term needs a label (`obsolete-missing-label-violation.sparql`).
- Terms that were never in a release can just be deleted: no obsoletion needed.
- Rebuild with `make ../patterns/definitions.owl components/obsoletes.owl`.

## Running ODK

- `src/ontology/run.sh` uses `docker run -ti` and **fails silently without a TTY** (agents, CI). Call docker directly with `-i`, image tag from CI (`.github/workflows/qc.yml`), CWD `src/ontology`:
  `docker run --rm -i -v "$PWD":/work -w /work/src/ontology -e ROBOT_JAVA_ARGS=-Xmx8G obolibrary/odkfull:v1.7 make ...`
- Regenerate pattern terms: `make GITHUB_ACTION=true ../patterns/definitions.owl`.
- Full QC, the same as CI: `make test IMP=false MIR=false`. Use `make -k` to see every failure, not just the first.
- **Read the dosdp output, not just the exit code.** `is missing column for pattern variable <x>` means a pattern variable and a TSV column disagree; dosdp silently drops every axiom that uses that variable and the build still passes (only `missing_definition` WARNs go up).
- **Refreshing the merged import** (`make refresh-imports`, needs ~36 GB for ROBOT; ODK 1.7 removed `refresh-merged`): regenerate `definitions.owl` first. `refresh-imports` runs `make clean`, which wipes `tmp/`. If you skip the mirror download with `make no-mirror-refresh-imports`, delete `tmp/all_pattern_terms.txt` and `tmp/seed.txt` first: the seed is built from those files, and a stale copy silently leaves out the new fillers.
- After a run, restore files the test rebuilt but you did not mean to change (`src/ontology/reports/*`, `components/obsoletes.owl` version bumps) before committing.

## Editing files

- Some files use CRLF line endings (e.g. `oba-efo.sssom.tsv`). Edit in binary mode or with an editor that preserves them, and check `git diff --stat` before committing: a one-line change must not become a whole-file diff.
- `src/ontology/imports/merged_import.owl` is ~52 MB, so pushes print GitHub's "larger than the recommended maximum file size of 50.00 MB" / GH001 warning. That is expected: do not flag it or propose LFS/CI changes below **85 MB** (GitHub hard-rejects at 100 MB). Check with `git cat-file -s HEAD:src/ontology/imports/merged_import.owl`.

## GitHub workflow

- Commit on a branch (e.g. `issue-NNN`), never on `master`. If you already have a PR for the issue, continue on its branch.
- Commit messages and PR descriptions say what changed and why.
- Do not add AI attribution (no "Generated with", co-author trailers or signatures) to commits, PRs, issues or comments.
- If you are not confident how to proceed, ask a clarifying question on the issue instead of guessing.
