# The release workflow 
The release workflow recommended by the ODK is based on GitHub releases and works as follows:

1. Run a release with the ODK
2. Review the release
3. Merge to main branch
4. Create a GitHub release

These steps are outlined in detail in the following.

## Run a release with the ODK

Preparation:

1. Ensure that all your pull requests are merged into your main (master) branch. Merge as many open PRs as possible.
2. Make sure that all changes to master are committed to GitHub (`git status` should say that there are no modified files).
3. Locally make sure you have the latest changes from master (`git pull`). You can also use [GitHub Desktop](https://desktop.github.com/) for interacting with the OBA repo.
4. Checkout a new branch (e.g. `git checkout -b release-202X-XX-XX`)
5. You may or may not want to refresh your imports as part of your release strategy (see [here](UpdateImports.md)).
6. Make sure you have the latest ODK installed by running `docker pull obolibrary/odkfull`
    ```shell
    docker pull obolibrary/odkfull
    ```

To actually run the release, you:

1. Open a command line terminal window and navigate to the `src/ontology` directory (`cd bio-attribute-ontology/src/ontology`).
2. Start the release pipeline by issuing the command:
    ```shell
    sh run.sh make prepare_release_fast
    ```
    NOTE: It is recommended that you run the release pipeline uncoupled from refreshing imports. However, in case you do need to refresh all the imports at this time, you can achieve that by:
    ```shell
    sh run.sh make prepare_release -B
    ```
3. If everything went well, you should see the following output on your machine:
    ```shell
    ...
    Release files are now in ../.. - now you should commit, push and make a release         on your git hosting site such as GitHub or GitLab
    make[1]: Leaving directory '/work/src/ontology'
    Please remember to update your ODK image from time to time: https://oboacademy.github.io/obook/howto/odk-update/.
    ```
    This will create all the specified release targets (OBO, OWL, JSON, and the variants, ont-full and ont-base) and copy them into your release directory (the top level of your repo).

## Review the release

1. You should check in Protégé if there are any obvious errors in the ontology artefacts, for example, if there are unsatisfiable classes in `oba.owl` or `oba.obo. Two simple additional checks: 
    1. Does the very top level of the hierarchy look ok? This means that all new terms have been imported/updated correctly.
    2. Does at least one change that you know should be in this release appear? For example, a new class. This means that the release was actually based on the recent edit file. 
2. Commit your changes to the branch and create a pull request and request another pair of eyes to review it.
3. In your GitHub pull request, review the following three files in detail (based on our experience):
    1. `oba.obo` - this reflects a useful subset of the whole ontology (everything that can be covered by OBO format). OBO format has that speaking for it: it is very easy to review!
    2. `oba-base.owl` - this reflects the asserted axioms in your ontology that you have actually edited.
    3. Ideally also take a look at `oba-full.owl`, which may reveal interesting new inferences you did not know about. Note that the diff of this file is sometimes quite large.
4. Like with every pull request, we recommend to always employ a second set of eyes when reviewing a PR!

## Merge the main branch
Once your [CI checks](ContinuousIntegration.md) have passed, and your reviews are completed, you can now merge your `release-202X-XX-XX` branch into the main OBA branch (don't forget to delete the branch afterwards - a big button will appear after the merge is finished).

## Create a GitHub release

Use the [github web interface](https://docs.github.com/repositories/releasing-projects-on-github/managing-releases-in-a-repository?tool=webui) to create a new OBA release.

- There should be 12 recently modified files in the root directory of the local copy of the repo:
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

- NOTE: GitHub imposes size constraints on repositories. The combined size of the OBA artefacts exceeds the GitHub imposed size limit. For this reason, some of the large release artefact files are not under GitHub version control. However, **all the 15 newly created ontology artefact files need to be included in the public release as binary files**. For background information on release artefacts, see
    - [OWL, OBO, JSON? Base, simple, full, basic? What should you use, and why?](https://oboacademy.github.io/obook/explanation/owl-format-variants/)
    - [Release artefacts](https://oboacademy.github.io/obook/reference/release-artefacts/)

1. Navigate to the ['Releases' page of OBA](https://github.com/obophenotype/bio-attribute-ontology/releases)
2. Click `Draft a new release`.
Click `Chose a tag`, and create a new tag based on the date on which your ontologies were build. You can find this, for example, by looking into the oba.obo file and checking the `data-version:` property. The date needs to be prefixed with a `v`, so, for example `v2022-10-17`.
3. For the title, you can use the date of the ontology build again, for example `2022-10-17 release`
4. Drag and drop the files listed above or [manually select them in the binaries box.](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) using the github web user-interface.
5. You can [automatically generate release notes.](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes)
6. Click `Publish release`. Done.

* * * *

## Debugging typical ontology release problems

### Problems with memory

When you are dealing with large ontologies, you need a lot of memory. When you see error messages relating to large ontologies such as CHEBI, PRO, NCBITAXON, or Uberon, you should think of memory first, see [here](https://github.com/INCATools/ontology-development-kit/blob/master/docs/DealWithLargeOntologies.md).

### Problems when using OBO format based tools

Sometimes you will get cryptic error messages when using legacy tools using OBO format, such as the ontology release tool (OORT), which is also available as part of the ODK docker container. In these cases, you need to track down what axiom or annotation actually caused the breakdown. In our experience (in about 60% of the cases) the problem lies with duplicate annotations (`def`, `comment`) which are illegal in OBO. Here is an example recipe of how to deal with such a problem:

1. If you get a message like `make: *** [cl.Makefile:84: oort] Error 255` you might have a OORT error. 
2. To debug this, in your terminal enter `sh run.sh make IMP=false PAT=false oort -B` (assuming you are already in the ontology folder in your directory) 
3. This should show you where the error is in the log (eg multiple different definitions) 
WARNING: THE FIX BELOW IS NOT IDEAL, YOU SHOULD ALWAYS TRY TO FIX UPSTREAM IF POSSIBLE
4. Open `oba-edit.owl` in Protégé and find the offending term and delete all offending issue (e.g. delete ALL definition, if the problem was "multiple def tags not allowed") and save. 
*While this is not idea, as it will remove all definitions from that term, it will be added back again when the term is fixed in the ontology it was imported from and added back in.
5. Rerun `sh run.sh make IMP=false PAT=false oort -B` and if it all passes, commit your changes to a branch and make a pull request as usual.

