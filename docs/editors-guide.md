# Local development workflows with OBA

<a id="edit-files"></a>

## Edit files

There are three kinds of files to edit in OBO explained in the following:

- The normal OBA edit file (`src/ontology/obo-edit.obo`)
- The OBA SSSOM mappings (`src/mappings/*`)
- The OBA DOSDP pattern files (`src/patterns/data/default/*`)

### The OBA edit file

As opposed to other ontologies, the OBA edit file (`src/ontology/obo-edit.obo`) **is barely used**. Power curators will use the oba-edit.obo file occasionally to edit the class hierarchy, but as per OBA principles, the class hierarchy is mostly created by reasoning. Most of OBA editing happens by editing the DOSDP templates, see below.

### The OBA SSSOM mappings 

- [OBA-VT SSSOM Mapping](https://docs.google.com/spreadsheets/d/13qh7dLE38vMyz91oRqj6GzKjFohNazNKAJxKG6Plw1o/edit#gid=506793298): The official mappings between OBA and VT. Source of truth is on Google Sheets, not Github.
- [OBA-EFO SSSOM Mapping](https://docs.google.com/spreadsheets/d/13qh7dLE38vMyz91oRqj6GzKjFohNazNKAJxKG6Plw1o/edit#gid=1005741851): The official mappings between OBA and EFO. Source of truth is on Google Sheets, not Github.
- [OBA-EFO Excluded Mapping](https://docs.google.com/spreadsheets/d/13qh7dLE38vMyz91oRqj6GzKjFohNazNKAJxKG6Plw1o/edit#gid=1005741851): Terms from EFO that have been reviewed and deemed out of scope for OBA. Source of truth is on Google Sheets, not Github.
- [OBA-VT Excluded Mapping](https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=2051840457&single=true&output=tsv): Terms from EFO that have been reviewed and deemed out of scope for OBA. Source of truth is on Google Sheets, not Github.

### The OBA DOSDP patterns

All OBA DOSDP data tables can be found [here](https://github.com/obophenotype/bio-attribute-ontology/tree/master/src/patterns/data/default).

DOSDP tables are the main way to edit OBA. You can edit the DOSDP TSV files using a regular text editor or a spreadsheet editor.

The main rule is, make sure to review the diff before making a pull request - the diff should only show the things you have actually changed.

## Updating SSSOM mapping files

```
cd src/ontology
sh run.sh make sync_sssom_google_sheets
```

## Creating/updating terms

<a id="alignment"></a>
## Preparing alignment work

1. Update the data required for the alignment: `sh run.sh make prepare_oba_alignment -B`. This will take a while, as a lot of ontologies are downloaded and syncronised.
1. Start jupyter in your local environment
1. Open `src/scripts/oba_alignment.ipynb` in your Jupyter environment and run all _over night_.
1. While the above is running, read everything in the notebook carefully to get a sense what the notebook is doing. The methods section can be skipped during the first read through, but it will likely be necessary to review these in later stages of the alignment process.
1. The notebook run will produce the following files:
    * `src/mappings/oba-vt-unreviewed.sssom.tsv`: VT mappings identified by pipeline but not reviewed
    * `src/mappings/oba-vt-missed.sssom.tsv`: VT mappings identified by looking at OBA IRIs (no need for review)
    * `src/mappings/oba-vt-unmapped.sssom.tsv`: VT terms that have not been mapped so far (excluding reviewed and candidate mappings)
    * `src/mappings/oba-vt-unreviewed.dosdp.tsv`: VT terms with candidate DOSDP pattern fillings.
    * `src/mappings/oba-efo-unreviewed.sssom.tsv`: see above vt analog
    * `src/mappings/oba-efo-unmapped.sssom.tsv`: see above vt analog
    * `src/mappings/oba-efo-unreviewed.dosdp.tsv`: see above vt analog

## Curating EFO alignment

1. Follow the steps in the [preparing alignment workflow](#alignment)
1. The central pieces for the EFO alignment, if of interest, can be found in the section starting with `OBA-EFO Alignment` in `src/scripts/oba_alignment.ipynb`.
1. Review `src/mappings/oba-efo-unreviewed.sssom.tsv`. These are the new mapping suggestions as determined by the mapping pipeline. Review mappings 1 x 1 and copy them into the official EFO-OBA SSSOM mapping [curated on Google Sheets](#edit-files).
1. Review `src/mappings/oba-efo-unreviewed.dosdp.tsv`. This is the hardest part. The table only provides a handful of suggests on how to map the label using DOSDP. You will have to go through the table `subject_id` by `subject_id` and identify the correct corresponding [DOSDP pattern tables](#edit-files). Important: when you create an ID (`defined_class` column DOSDP table) for an EFO-sourced class, you have to **add a respective mapping** to the official EFO-OBA SSSOM mapping [curated on Google Sheets](#edit-files).
1. Optional: Review `src/mappings/oba-efo-unmapped.sssom.tsv` to figure out what to do about entirely unmapped EFO terms. These may need some careful planning and adjustments of the alignment code.

## Curating VT alignment

1. Follow the steps in the [preparing alignment workflow](#alignment)
1. The central pieces for the EFO alignment, if of interest, can be found in the section starting with `OBA-VT Alignment` in `src/scripts/oba_alignment.ipynb`.
1. Review `src/mappings/oba-vt-missed.sssom.tsv`. This should ideally be empty - these are mappings that have not been factored into the official oba-vt mappings yet, but have the VT-style IRI (`OBA:VT0010108`) which suggests that the class was derived from the respective VT id. Add all mappings in `oba-vt-missed.sssom.tsv` to the official VT-OBA SSSOM mapping [curated on Google Sheets](#edit-files).
1. Review `src/mappings/oba-vt-unreviewed.sssom.tsv`. These are the new mapping suggestions as determined by the mapping pipeline. Review mappings 1 x 1 and copy them into the official VT-OBA SSSOM mapping [curated on Google Sheets](#edit-files).
1. Review `src/mappings/oba-vt-unreviewed.dosdp.tsv`. This is the hardest part. The table only provides a handful of suggests on how to map the label using DOSDP. You will have to go through the table `subject_id` by `subject_id` and identify the correct corresponding [DOSDP pattern tables](#edit-files). Important: when you create an ID (`defined_class` column DOSDP table) for a VT-sourced class, you add a special IRI that looks like `OBA:VT123`. This way, mappings will be curated automatically by the framework and you dont have to add them manually.
1. Optional: Review `src/mappings/oba-vt-unmapped.sssom.tsv` to figure out what to do about entirely unmapped VT terms. These may need some careful planning and adjustments of the alignment code.


### Adding "measured in" annotations

1. Go to [Google sheet for "measured in" annotations](https://docs.google.com/spreadsheets/d/13qh7dLE38vMyz91oRqj6GzKjFohNazNKAJxKG6Plw1o/edit#gid=1857133171) and add annotations
1. Go to `cd src/ontology` in your terminal
1. Create a new branch with your favourite tool
1. Run `sh run.sh make sync_templates_google_sheets` to sync templates from Google sheets
1. Convince yourself in your favourite git diff tool (GitHub Desktop!) that the changed tables look as intended!
1. In your terminal, run `sh run.sh make recreate-measured_in`
1. When completed, the file `src/ontology/components/measured_in.owl` should have been updated. Look at the diff again to convince yourself that the changes look as intended. You may want to open `oba-edit.obo` in Protege to look at one or two changes!
1. Make sure you are on your new branch created above and commit changes to branch.
1. Publish branch (push to GitHub), make pull request, assign reviewer.

### Adding synonym

1. Follow the instructions for adding "measured in" annotations above, except:
   - Add the synonyms [in this sheet here](https://docs.google.com/spreadsheets/d/13qh7dLE38vMyz91oRqj6GzKjFohNazNKAJxKG6Plw1o/edit#gid=473147169)
   - Instead of `sh run.sh make recreate-measured_in`, `sh run.sh make recreate-synonyms`