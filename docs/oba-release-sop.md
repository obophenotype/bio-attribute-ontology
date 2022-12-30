Release Workflow for the Ontology of Biological Attributes (OBA)
================================================================


* Make sure you have the latest ODK installed by running docker:

```shell
docker pull obolibrary/odkfull
```

* Merge as many open PRs as possible.
* Start with a fresh copy of the `master` branch. For the next steps you can use [GitHub Desktop](https://desktop.github.com/) or the command line instructions below. 

```shell
git pull
```

Create a new branch:

```shell
git checkout -b release-202X-XX-XX
```

In a terminal window, start the release pipeline:

```shell
sh run.sh make prepare_release_fast
```

NOTE: It is recommended that running the release pipeline is uncoupled from refreshing imports. However, inn case you need to refresh all the imports, you can achieve that by:

```shell
sh run.sh make prepare_release -B
```

- [ ] If everything went all right, you should see message similar to the one below in your terminal window:

> ...
> Release files are now in ../.. - now you should commit, push and make a release         on your git hosting site such as GitHub or GitLab
> make[1]: Leaving directory '/work/src/ontology'
> Please remember to update your ODK image from time to time: https://oboacademy.github.io/obook/howto/odk-update/.


### Check and package the release artefacts for OBA

- [ ] You should also check in Protege if the new terms you just added look fine.
- [ ] Open in Protege some of the OBA release artefacts and check for any potential errors.
For example, check if there are any unsatisfiable classes in `oba.obo`.


For background information on release artefacts, see
* [OWL, OBO, JSON? Base, simple, full, basic? What should you use, and why?](https://oboacademy.github.io/obook/explanation/owl-format-variants/)
* [Release artefacts](https://oboacademy.github.io/obook/reference/release-artefacts/)

GitHub imposes some size constraints. The size of all the OBA artefacts exceeds the GitHub imposed size limit, but you can attach all the release artefacts as binary files to the release product.

### Make a release and include all the release files (including oba-base.owl and oba.obo) as binary files

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

NOTE: some of these large files are not under GitHub version control, but they all need to be included in the release as binary files. 

- [ ] Navigate to the ['Releases' page of OBA](https://github.com/obophenotype/bio-attribute-ontology/releases)
- [ ] Click `Draft a new release`.
Click `Chose a tag`, and create a new tag based on the date on which your ontologies were build. You can find this, for example, by looking into the oba.obo file and checking the `data-version:` property. The date needs to be prefixed with a `v`, so, for example `v2022-10-17`.
- [ ] For the title, you can use the date of the ontology build again, for example `2022-10-17 release`
- [ ] Drag and drop the files listed above or [manually select them in the binaries box.](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) using the github web user-interface.
- [ ] You can [automatically generate release notes.](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes)
- [ ] Click "Publish release". Done.

