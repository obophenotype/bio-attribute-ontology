# 0001: A gene product is a PRO class, not a ChEBI class

| | |
|---|---|
| Status | accepted; existing terms are being re-pointed in [#486](https://github.com/obophenotype/bio-attribute-ontology/issues/486) |
| Date | 2026-11-19 |
| Issues | [#484](https://github.com/obophenotype/bio-attribute-ontology/pull/484) review, [#486](https://github.com/obophenotype/bio-attribute-ontology/issues/486) |
| Affects | `entity_attribute_location.tsv` and any pattern with a chemical or protein filler |

## Question

ChEBI has classes for some proteins (myoglobin, insulin, hemoglobin), and PRO
has classes for the same proteins. When an OBA trait is about a protein, which
one is the filler?

## Context

ChEBI's protein classes sit in its chemical hierarchy: `CHEBI:7044` myoglobin
is a `CHEBI:5386` globin. Some are species-specific without saying so in a way
OBA can use: `CHEBI:5931` is labelled "insulin (human)", so a ChEBI filler
produced the species-qualified label *amount of insulin (human)*. PRO
classes are tied to genes and to UniProt, and have species-neutral forms
(see [0002](0002-species-neutral-protein-fillers.md)).

When #484 added location-neutral amount classes, using both ChEBI and PRO
produced duplicate classes for the same substance. For example, myoglobin had
both a ChEBI and a PRO amount class.

The Translator node-normalization discussion (*One Name, Many Things*, Spring
2026) has the same problem from the other side. A search for "insulin" returns
both `CHEBI:5931` and `UniProtKB:P01308`. Its proposal is "precise proteins,
squishy chemicals": proteins map strictly to UniProtKB, and broad or ambiguous
readings go into the chemical set.

## Decision

When the entity is a gene product (a polypeptide encoded by a gene, or one of
its isoforms or modified forms), the filler is a PRO class, even when ChEBI
also has one. ChEBI is used for chemicals, including small peptides and
drugs that are not treated as gene products.

Assemblies of gene products are covered by
[0003](0003-protein-assemblies.md).

## Consequences

- For OBA: the rows listed in #486 (`OBA:VT0006034`, `OBA:VT1000764`,
  `OBA:VT0010470`) are re-pointed from ChEBI to `PR:000010213` myoglobin and
  `PR:000009054` insulin. Other ChEBI fillers that are really proteins should
  be swept for and treated the same way.
- For Translator: this matches the "precise proteins" side of the proposal.
  OBA's protein traits point at the protein, and the chemical/drug reading of
  "insulin" is left to ChEBI and the drug vocabularies.

## Open questions

- Peptide hormones and short peptides that ChEBI models structurally (e.g. by
  sequence) and PRO also covers. A rule is needed for which to use.
