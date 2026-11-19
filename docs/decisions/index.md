# Entity decisions

One name often covers several different things. "Insulin" is a gene, a
protein, a drug and a dose; "hemoglobin" is a ChEBI chemical, a GO complex,
seven globin chains and their genes; "collagen" is a ChEBI mixture, a family of
GO trimers and dozens of PRO chains. Every OBO ontology that refers to such an
entity has to pick one of those classes, and when ontologies pick differently,
the data they annotate stops joining up.

This register records those choices: **which class stands for an entity when
several ontologies offer one**, why, and what follows for everyone else. It is
kept in OBA because OBA makes the choice more often than any other ontology:
nearly every OBA trait is defined by composing an attribute with an entity
taken from ChEBI, PRO, GO, CL or Uberon, so the choice is fixed in its
logical definitions. From there it reaches uPheno, the GWAS Catalog and EFO, the
VT and LOINC mappings, and knowledge graphs such as the NCATS Biomedical Data
Translator. Recording a decision once, here, with the alternatives and their
identifiers, lets other ontologies follow it or map to it instead of making it
again.

## Scope

In scope: choosing between classes in **different** resources, or between
different granularities, for the same named entity. For example:

- chemical vs protein vs complex vs gene vs mixture;
- species-neutral vs species-specific gene products;
- an assembled complex vs its constituent chains;
- a fluid or compartment vs the location the sample came from.

Out of scope: modelling questions internal to one ontology. Raise those on that
ontology's tracker.

## Register

| ID | Decision | Status | Issues |
|---|---|---|---|
| [0001](0001-proteins-are-not-chemicals.md) | A gene product is a PRO class, not a ChEBI class | accepted | [#486](https://github.com/obophenotype/bio-attribute-ontology/issues/486) |
| [0002](0002-species-neutral-protein-fillers.md) | Prefer species-neutral PRO classes to species-specific ones | accepted, under discussion | [#397](https://github.com/obophenotype/bio-attribute-ontology/issues/397), [#269](https://github.com/obophenotype/bio-attribute-ontology/issues/269) |
| [0003](0003-protein-assemblies.md) | A protein assembly (hemoglobin, collagen, ferritin) is a GO complex | proposed | |

## Statuses

- **open**: the question is recorded, with the options, but nobody has proposed
  an answer.
- **proposed**: a record recommends an answer; OBA editors have not yet agreed.
- **accepted**: OBA editors have agreed; new terms must follow it and existing
  terms are brought into line.
- **superseded**: replaced by a later record, which the old one links to.

## Adding or changing a decision

1. Open an OBA issue describing the case, with the identifiers each resource
   offers. Look the identifiers up (OLS, or the Translator
   [Node Normalizer](https://nodenormalization-sri.renci.org/docs) to see how
   they are merged downstream); do not guess them.
2. Copy [the template](template.md) to `NNNN-short-name.md`, using the next
   free number, set the status to `proposed`, and add a row to the register
   above. Open a pull request linking the issue.
3. Tell the trackers of the ontologies and consumers the decision affects
   (ChEBI, PRO, GO, EFO, Translator/Babel, ...), and link those notifications
   from the record.
4. An OBA editor marks the record `accepted` when merging it, or after
   discussion. Once a record is accepted, follow-up work to bring existing
   terms into line gets its own issue.

Do not rewrite an accepted record to change its decision. Add a new record
that supersedes it, so the reasoning behind both stays readable.
