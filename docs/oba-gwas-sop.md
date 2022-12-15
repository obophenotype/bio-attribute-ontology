How to add new GWAS requested trait terms to OBA and EFO?
=========================================================


## 1. Check if an appropriate OBA trait pattern already exists
Look into [bio-attribute-ontology/src/patterns/dosdp-patterns/](https://github.com/obophenotype/bio-attribute-ontology/tree/master/src/patterns/dosdp-patterns) and check if the GWAS trait term would fit into any of the existing patterns.
- [ ] If yes, skip to the next step.
- [ ] If none of the existing OBA trait patterns look appropriate, then create a new pattern.
In some cases, the requested GWAS term may not fit the scope of OBA. In that case, an new EFO term can be created without an equivalent OBA trait term.

## 2. Create new OBA term(s)

* Create a new github branch for the edits.

* Fill in the appropriate [DOS-DP template data table](https://oboacademy.github.io/obook/tutorial/dosdp-odk/) to add any new terms to OBA in [bio-attribute-ontology/src/patterns/data/default/](https://github.com/obophenotype/bio-attribute-ontology/tree/master/src/patterns/data/default).

For example, for a trait involving the 'age at which disease manifestations first appear', fill in the table [`disease_onset.tsv`.](https://github.com/obophenotype/bio-attribute-ontology/blob/master/src/patterns/data/default/disease_onset.tsv).
Create a unique OBA identifier by using the next available ID from your [assigned range.](https://github.com/obophenotype/bio-attribute-ontology/blob/master/src/ontology/oba-idranges.owl)

Also fill in the appropriate columns for the variable fields as specified in the actual DOS-DP `yaml` template file.
For example, in the case of the [`disease_onset.tsv`.](https://github.com/obophenotype/bio-attribute-ontology/blob/master/src/patterns/data/default/disease_onset.tsv) table, you must use MONDO [disease or disorder](https://www.ebi.ac.uk/ols/ontologies/mondo/terms?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FMONDO_0000001) terms in the `disease` column.

NOTE: Keep track of the IDs from your range that you have already assigned.

* Create a pull request (PR) with the edits. Request other people to review your PR.
* If approved, merge the PR after the review(s) into the 'master' branch. 

## 3. OBA release

The newly created trait terms can be imported into EFO from a publicly released version of OBA.

To run the OBA release pipeline, follow the instructions in the document [Release Workflow for the Ontology of Biological Attributes (OBA)](./OBA_ReleaseWorkflow.md).


## 4. Provide the new OBA terms to EFO

- [ ] Add the newly created OBA term IRI and also all its component term IRIs to [oba_terms.txt](https://github.com/EBISPOT/efo/tree/master/src/ontology/iri_dependencies) so that they [get included](https://github.com/EBISPOT/efo/issues/1382#issuecomment-1117247895) in [EFO dynamic imports.](https://github.com/EBISPOT/efo/blob/master/src/ontology/README-editors.md) By component terms I mean all those terms that are used in the DOS-DP data filler table to compose the OBA term (terms from MONDO, UBERON, PATO, etc.) as specified in the corresponding DOS-DP pattern file.
    - NOTE: use full IRI, i.e:

    ```
    http://purl.obolibrary.org/obo/OBA_2040167
    http://purl.obolibrary.org/obo/MONDO_0000481
    ```

- [ ] This step depends on a new public OBA release.
- [ ] You need to accomplish this in an [EFO PR](https://github.com/EBISPOT/efo).

* * * * * * * * * * * * * * * * * * *
