How to add new GWAS requested trait terms to OBA and EFO?
=========================================================


## 1. Check if an appropriate OBA trait pattern already exists
Look into [bio-attribute-ontology/src/patterns/dosdp-patterns/](https://github.com/obophenotype/bio-attribute-ontology/tree/master/src/patterns/dosdp-patterns) and check if the GWAS trait term would fit into any of the existing patterns.
- [ ] If yes, skip to the next step.
- [ ] If none of the existing OBA trait patterns look appropriate, then create a new pattern.
In some cases, the requested GWAS term may not fit the scope of OBA. In that case, an new EFO term can be created without an equivalent OBA trait term.

## 2. Create new OBA term(s)
Fill in the appropriate [DOS-DP template data table](https://oboacademy.github.io/obook/tutorial/dosdp-odk/) to add any new terms to OBA in [bio-attribute-ontology/src/patterns/data/default/](https://github.com/obophenotype/bio-attribute-ontology/tree/master/src/patterns/data/default).
For example, for a trait involving the 'age at which disease manifestations first appear', fill in the table [`disease_onset.tsv`.](https://github.com/obophenotype/bio-attribute-ontology/blob/master/src/patterns/data/default/disease_onset.tsv).
Create a unique OBA identifier by using the next available ID from your [assigned range.](https://github.com/obophenotype/bio-attribute-ontology/blob/master/src/ontology/oba-idranges.owl)

Keep track of the IDs from your range that you have already assigned.

Also fill in the appropriate terms as specified in the actual DOS-DP `yaml` template file.
For example, in the case of the [`disease_onset.tsv`.](https://github.com/obophenotype/bio-attribute-ontology/blob/master/src/patterns/data/default/disease_onset.tsv) table, you must use MONDO [disease or disorder](https://www.ebi.ac.uk/ols/ontologies/mondo/terms?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FMONDO_0000001) terms in the `disease` column.

## 3. OBA release

The newly created trait terms can be imported into EFO from a publicly released version of OBA.   
To run the OBA release pipeline, follow the steps below.

* Make sure you have the latest ODK installed by running docker

    docker pull obolibrary/odkfull

* Merge as many open PRs as possible
* Start with a fresh copy of the `master` branch

    git pull

* Checkout a new branch

    git checkout -b release-202X-XX-XX

* In a terminal window, start the [release pipeline:](http://pato-ontology.github.io/pato/odk-workflows/ReleaseWorkflow/)

```shell
sh run.sh make prepare_release -B
```

* Alternatively, if you do not need to refresh all the imports, run a fast release:

```shell
sh run.sh make prepare_release_fast
```


- [ ] If everything went well, you should see this message in your terminal window:

>
...
Release files are now in ../.. - now you should commit, push and make a release         on your git hosting site such as GitHub or GitLab
make[1]: Leaving directory '/work/src/ontology'
Please remember to update your ODK image from time to time: https://oboacademy.github.io/obook/howto/odk-update/.


### Check and package the release artefacts for OBA

- [ ] Open in Protege some of the OBA release artefacts and check for any errors For example, are there any unsatisfiable classes in `oba.obo`?

- [ ] You should also check in Protege if the new terms you just added look fine.

For some background information on release artefacts, see
* [OWL, OBO, JSON? Base, simple, full, basic? What should you use, and why?](https://oboacademy.github.io/obook/explanation/owl-format-variants/)
* [Release artefacts](https://oboacademy.github.io/obook/reference/release-artefacts/)

GitHub imposes some size constraints. The size of all the OBA artefacts exceeds the GitHub imposed size limit, but you can attach all the release artefacts as binary files to the release product.

### Make a release and include all the release files (including oba-base.owl and oba.obo) as binary files
- There should be 12 recently modified files:
    1. oba-base.json
    2. oba-base.obo
    3. oba-base.owl
    4. oba-basic.json
    5. oba-basic.obo
    6. oba-basic.owl
    7. oba-full.json
    8. oba-full.obo
    9. oba-full.owl
    10. oba.json
    11. oba.obo
    12. oba.owl

NOTE: some of these large files are not under GitHub version control, but they all need to be included in the release as binary files. 

- [x] Drag and drop or [manually select files in the binaries box.](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) on GitHub.com.

## 4. Provide the new OBA terms to EFO

- [ ] Add the new OBA term IRIs that you created to [oba_terms.txt](https://github.com/EBISPOT/efo/tree/master/src/ontology/iri_dependencies) that are [to be included](https://github.com/EBISPOT/efo/issues/1382#issuecomment-1117247895) in [EFO dynamic imports.](https://github.com/EBISPOT/efo/blob/master/src/ontology/README-editors.md)
    - NOTE: use full IRI, i.e:

```
http://purl.obolibrary.org/obo/OBA_2040165
http://purl.obolibrary.org/obo/OBA_2040166
```

- [ ] This step depends on a new public OBA release.
- [ ] You need to accomplish this in an [EFO PR](https://github.com/EBISPOT/efo).
