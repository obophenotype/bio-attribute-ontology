# 0002: Prefer species-neutral PRO classes to species-specific ones

| | |
|---|---|
| Status | accepted as current practice (`AGENTS.md`); the underlying question is still under discussion |
| Date | 2026-11-19 |
| Issues | [#269](https://github.com/obophenotype/bio-attribute-ontology/issues/269), [#397](https://github.com/obophenotype/bio-attribute-ontology/issues/397), [#486](https://github.com/obophenotype/bio-attribute-ontology/issues/486) |
| Affects | every protein filler; GWAS Catalog use of OBA; Translator |

## Question

PRO has a species-neutral class for most proteins (`PR:000050026` hemoglobin
subunit beta, "a translation product of the human HBB gene or a 1:1 ortholog
thereof") and species-specific classes beneath it (`PR:P68871` hemoglobin
subunit beta (human)). Which one does an OBA trait use?

## Context

The arguments are set out in #269 and #397:

- **For species-neutral:** one trait term can annotate human, mouse and
  rat data, which is the cross-species integration OBA exists for. It avoids
  one term per UniProt accession. Homology is already built into ontologies
  such as Uberon. The GWAS Catalog's protein traits come from EFO terms that
  never named a species, so a neutral class is at least as specific.
- **For species-specific:** UniProt accessions are well understood, and
  the neutral classes are mostly shadows of the human entry. Their groupings
  are less stable as identifiers. There is no simple procedure when no 1:1
  ortholog exists. Cross-species generalization can be done at query time
  with a homology resource. Only the species-specific PRO classes carry
  UniProt cross-references, which the GWAS Catalog needs.

OBA's current practice, written into `AGENTS.md`, is to use the species-neutral
class. Species-specific classes appear where no neutral class exists, or where
the PRO slim does not link the two (#486 lists 107 such fillers and their
causes).

How the identifiers behave downstream, checked against the Translator Node
Normalizer on 2026-11-19:

| filler | normalizes to |
|---|---|
| `PR:000050026` hemoglobin subunit beta | itself only: no UniProtKB, no gene |
| `PR:000003264` collagen alpha-1(I) chain | itself only |
| `PR:P68871` hemoglobin subunit beta (human) | `UniProtKB:P68871`, and with gene/protein conflation `NCBIGene:3043` HBB |
| `PR:P02452` collagen alpha-1(I) chain (human) | `UniProtKB:P02452`, and with conflation `NCBIGene:1277` COL1A1 |

So a trait with a species-neutral filler is not linked to any gene or protein
in Translator. PRO has the link (`PR:P68871` is a subclass of
`PR:000050026`, and the slim keeps that axiom), but the Node Normalizer
does not use it.

## Decision

Use the species-neutral PRO class when one exists and the slim links it to the
species-specific classes. Fall back to the species-specific class otherwise.
This stays the rule until #397 is settled.

## Consequences

- For OBA: species-specific fillers that do have a linked neutral parent
  should be re-pointed (see #486 for the slim gaps that block some of them).
- For the GWAS Catalog: UniProt cross-references have to be supplied
  separately, e.g. injected from the species-specific subclasses as suggested
  in #397.
- For Translator: ask the Babel maintainers to connect a species-neutral PRO
  class to its human subclass, and so to the human UniProtKB entry and gene,
  when PRO asserts a single human subclass. Until then OBA's protein traits are
  disconnected nodes there.

## Open questions

- Whether OBA should carry both forms, with the species-specific classes as
  children, as suggested in #397.
- What to do for organisms PRO does not cover.
