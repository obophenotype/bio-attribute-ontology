These notes are for the EDITORS of oba

For more details on ontology management, please see the OBO tutorial:

 * https://github.com/jamesaoverton/obo-tutorial

## Source Files

All source files are in this directory (src/ontology)

This is arranged differently than other ontologies. The source is in
two parts:

 * The editors core [oba-edit.obo](oba-edit.obo)
 * [modules](modules/)
    * [modules/entity_attribute.tsv](modules/entity_attribute.tsv)
    * [modules/entity_attribute_location.tsv](modules/entity_attribute_location.tsv)

Most of the classes in OBA conform to a stereotypical compositional
pattern. Rather than edit these in an ontology editor, they are
specified in tabular format in the TSV files.

These are then compiled down into OBO/OWL during the build process,
according to design pattern specifications. See the [patterns folder](../patterns) for more details.

## Building the ontology

The ontology is built by running

    make

From the src/ontology directory

As a first step, all modules are compiled down into OWL (see the
[travis config](../../.travis.yml) for dependencies).

The OWL versions of the module files are combined with the core module
using OWL tools.

Note that a GCI module also gets built for each module. This contains
GCIs of the form:

    (morphology and inheres-in some part-of some head) SubClassOf part-of some (morphology and inheres-in some head)

Effectively this shadows the partonomy from the entity ontology in the trait ontology.

We materialize this inferred partonomy using owltools - see the
makefile for details. The end result is that we have an ontology with
axioms such as

    'ear morphology' SubClassOf part-of some 'head morphology'

## ID Ranges

TODO - these are not set up

These are stored in the file

 * [oba-idranges.owl](oba-idranges.owl)

** ONLY USE IDs WITHIN YOUR RANGE!! **


## Release Manager notes

You should only attempt to make a release AFTER the edit version is
committed and pushed, and the travis build passes.

to release:

    cd src/ontology
    make

If this looks good type:

    make prepare_release

This generates derived files such as oba.owl and oba.obo and places
them in the top level (../..). The versionIRI will be added.

Commit and push these files.

    git commit -a

And type a brief description of the release in the editor window

IMMEDIATELY AFTERWARDS (do *not* make further modifications) go here:

 * https://github.com/obophenotype/oba/releases
 * https://github.com/obophenotype/oba/releases/new

The value of the "Tag version" field MUST be

    vYYYY-MM-DD

The initial lowercase "v" is REQUIRED. The YYYY-MM-DD *must* match
what is in the versionIRI of the derived oba.owl (data-version in
oba.obo).

Release title should be YYYY-MM-DD, optionally followed by a title (e.g. "january release")

Then click "publish release"

__IMPORTANT__: NO MORE THAN ONE RELEASE PER DAY.

The PURLs are already configured to pull from github. This means that
BOTH ontology purls and versioned ontology purls will resolve to the
correct ontologies. Try it!

 * http://purl.obolibrary.org/obo/oba.owl <-- current ontology PURL
 * http://purl.obolibrary.org/obo/oba/releases/YYYY-MM-DD.owl <-- change to the release you just made

For questions on this contact Chris Mungall or email obo-admin AT obofoundry.org

# Travis Continuous Integration System

Check the build status here: [![Build Status](https://travis-ci.org/obophenotype/oba.svg?branch=master)](https://travis-ci.org/oba-ontology/oba)

This replaces Jenkins for this ontology

## General Guidelines

See:
http://wiki.geneontology.org/index.php/Curator_Guide:_General_Conventions
