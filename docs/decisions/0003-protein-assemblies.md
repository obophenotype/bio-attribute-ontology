# 0003: A protein assembly (hemoglobin, collagen, ferritin) is a GO complex

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-19 |
| Issues | none yet |
| Affects | `entity_attribute_location.tsv`, `entity_attribute.tsv`; ChEBI, GO and PRO; Translator |

## Question

Hemoglobin, collagen, ferritin, fibrinogen and the immunoglobulins are
assemblies of several gene products. A clinical "hemoglobin" test measures the
assembled tetramers, not any one chain. Which class is the filler for such an
entity: the ChEBI class, the GO complex, a PRO complex class, or the
individual PRO chains?

## Context

### What the resources offer

| | hemoglobin | collagen |
|---|---|---|
| ChEBI | `CHEBI:35143` hemoglobin, a `CHEBI:5386` globin and `CHEBI:746933` globular protein | `CHEBI:3815` Collagen, a `CHEBI:60027` polymer and a mixture; no definition |
| GO complex | `GO:0005833` hemoglobin complex | `GO:0005581` collagen trimer, with kinds (`GO:0005583` fibrillar collagen trimer, ...) and types (`GO:0005584` collagen type I trimer, ...) |
| PRO complex | under `GO:0005833`: `PR:000050469` hemoglobin A1c, `PR:000060250` methemoglobin, `PR:000060251` carboxyhemoglobin, `PR:000060254` oxyhemoglobin, `PR:000060255` deoxyhemoglobin, and human forms of these | none found |
| PRO chain | `PR:000050026` hemoglobin subunit beta, `PR:000008458` delta, ... | `PR:000003264` collagen alpha-1(I) chain, ... |

The clinically measured hemoglobin variants (HbA1c, methemoglobin,
carboxyhemoglobin) exist only as PRO complex classes, and all of them are
subclasses of the GO complex. None is a subclass of the ChEBI class.

### What OBA does today

OBA is inconsistent. Most assemblies use the GO complex:

| GO complex filler | example term |
|---|---|
| `GO:0070288` ferritin complex | `OBA:VT0010513` blood ferritin amount |
| `GO:0005577` fibrinogen complex | `OBA:0000061` circulating fibrinogen amount |
| `GO:0071736` IgG immunoglobulin complex, circulating (and IgA, IgE, IgM) | `OBA:VT0001805` blood immunoglobulin G amount |
| `GO:0005861` troponin complex, `GO:0043514` interleukin-12 complex, `GO:1990148` glutamate dehydrogenase complex, `GO:0019814` immunoglobulin complex | |

Hemoglobin is the exception and uses `CHEBI:35143` in 8 terms:
`OBA:VT0001588` blood hemoglobin amount, `OBA:VT0000315` urine hemoglobin
amount, `OBA:2045301` erythrocyte hemoglobin content trait, `OBA:2045305`,
`OBA:2045306`, `OBA:2045315`, `OBA:2045450` blood hemoglobin attribute, and the
unreleased `OBA:2100428` amount of hemoglobin. OBA has no term for collagen as
an assembly. It has 69 chain-level collagen terms over 44 PRO chains, and 20
hemoglobin chain-level terms.

The inconsistency has visible effects in the released ontology:

- `OBA:VT0010513` blood ferritin amount is classified under *cellular
  component attribute*, while `OBA:VT0001588` blood hemoglobin amount is
  classified under `OBA:2090007` *blood globulin amount*. The second
  inference comes from ChEBI's *globular protein* and is wrong clinically:
  serum "globulin" is total protein minus albumin and does not include
  hemoglobin.
- A future *amount of hemoglobin A1c* term (`PR:000050469`, already in
  OBA's import) would not classify under *blood hemoglobin amount*, because
  HbA1c is a subclass of `GO:0005833` and not of `CHEBI:35143`.

### What Translator does

Checked against the Translator Node Normalizer and Name Resolver on
2026-11-19. Neither entity has a single node.

| node | type | contents |
|---|---|---|
| `UMLS:C0019046` Hemoglobin (top search hit) | Protein | `NCIT:C16676`, `MESH:D006454`, `DRUGBANK:DB04945` |
| `CHEBI:35143` hemoglobin | ChemicalEntity | `MESH:D006454` again (that ID resolves to the UMLS node) |
| `UNII:VSU9IB86SP` HEMOGLOBIN | ChemicalEntity | itself only |
| `GO:0005833` hemoglobin complex | CellularComponent | `UMLS:C1166824` |
| `PUBCHEM.COMPOUND:133604` "Collagen" (top search hit) | SmallMolecule | a specific Lys-Pro-Gly-... peptide labelled "Collagen" from HMDB |
| `UMLS:C0009325` collagen | Protein | `NCIT:C16447`, `MESH:D003094` |
| `CHEBI:3815` Collagen | ChemicalMixture | `KEGG.COMPOUND:C00211` |
| `GO:0005581` collagen trimer | CellularComponent | `UMLS` |

The PRO complex classes (HbA1c, methemoglobin, ...) are not in the Node
Normalizer at all. The Translator proposal *One Name, Many Things* (Spring
2026) suggests putting broad readings such as "hemoglobin" in the chemical
set ("precise proteins, squishy chemicals"). That is a choice about where a
search for an ambiguous name should land. It does not say what an ontology
should use as a logical filler.

## Options

1. **ChEBI** (`CHEBI:35143`, `CHEBI:3815`). Lines up with Translator's
   chemical bucket. But it gives no home for HbA1c and the other measured
   variants, collagen has no definition, and it causes the globulin inference.
2. **GO complex, with PRO complex classes for specific forms.** Matches what
   OBA already does for ferritin, fibrinogen, immunoglobulins and troponin. The
   measured variants are its subclasses, and it is species-neutral.
3. **PRO complex only.** PRO has no general hemoglobin class; its complex
   classes sit under the GO class anyway, so this collapses into option 2.
4. **Chains only** (amount of HBB, HBA, ...). This is not what the assays
   measure, and a total has to be expressed as a sum.

## Decision (proposed)

Pick the filler for **what the measurement counts**:

| measured | filler | examples |
|---|---|---|
| one gene product | PRO, species-neutral ([0001](0001-proteins-are-not-chemicals.md), [0002](0002-species-neutral-protein-fillers.md)) | `PR:000050026` hemoglobin subunit beta; `PR:000003264` collagen alpha-1(I) chain |
| an assembly of gene products | GO complex | `GO:0005833` hemoglobin complex; `GO:0005581` collagen trimer; `GO:0005584` collagen type I trimer; `GO:0070288` ferritin complex |
| a modified, ligand-bound or species-specific form of an assembly | PRO complex class under the GO complex | `PR:000050469` hemoglobin A1c; `PR:000060250` methemoglobin |

ChEBI classes for proteins and protein assemblies (`CHEBI:35143`,
`CHEBI:3815`) are not used as fillers.

## Consequences

- For OBA: re-point the 8 hemoglobin terms from `CHEBI:35143` to
  `GO:0005833`, which is already imported. Labels do not change. The logical
  definitions do, so *blood hemoglobin amount* leaves *blood globulin amount*
  and is classified alongside *blood ferritin amount*. Mappings are keyed by
  OBA ID and are unaffected, but the VT and EFO alignments should be checked
  for anything that relied on the ChEBI parentage. New collagen assembly terms
  use `GO:0005581` or a type-specific trimer.
- For other ontologies: nothing is asked of ChEBI or GO. PRO may be asked
  for complex classes that OBA needs and lacks.
- For Translator, to raise with the Babel maintainers:
  - type GO protein-containing complexes as Biolink `MacromolecularComplex`,
    not `CellularComponent`;
  - load PRO's complex classes;
  - link `GO:0005833` and `GO:0005581` to wherever the broad "hemoglobin" and
    "collagen" readings are placed;
  - fix `MESH:D006454` appearing in two cliques, and the misleading
    "Collagen" label on `PUBCHEM.COMPOUND:133604`.

  OBA can publish the cross-resource correspondences above as an SSSOM mapping
  set, so that Babel can use them directly.

## Open questions

- Fragments and propeptides measured as markers, such as procollagen type I
  N-terminal propeptide (P1NP) and the C-terminal telopeptide (CTX). PRO has
  cleavage-product classes for collagen chains (e.g. `PR:000018798` collagen
  alpha-1(I) chain proteolytic cleavage product). Whether they cover each
  marker precisely enough has not been checked.
- "Total collagen" measured by hydroxyproline assay counts degraded as well as
  assembled collagen. Is `GO:0005581` close enough?
- Lipoprotein particles (`GO:0034364` high-density lipoprotein particle and
  similar) are assemblies too, but OBA models their cholesterol content with
  ChEBI classes such as `CHEBI:47775`. Is that a separate decision?
