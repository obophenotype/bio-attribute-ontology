# Ontology of Biological Attributes (OBA) Project Guide

This includes instructions for editing the OBA ontology. 

## Project Layout
- Main development file is `src/ontology/oba-edit.obo`
- ODK and ontology documentation can be found in `/docs/`

## Querying ontology

- To look at a specific term if you know the ID:
    - `obo-grep.pl -r 'id: OBA:2040177' src/ontology/oba-edit.obo`
- All mentions of an ID
    - `obo-grep.pl -r 'OBA:2040177' src/ontology/oba-edit.obo`
- Note that `obo-grep.pl` is in your PATH, no need to search for it    
- Only search over `src/ontology/oba-edit.obo`
- DO NOT bother doing your own greps over the file, or looking for other files, unless otherwise asked, you will just waste time.
- ONLY use the methods above for searching the ontology

## Before making edits
- Read the request carefully and make a plan, especially if there is nuance
- If related issues are mentioned read them: `gh issue view GITHUB-ISSUE-NUMBER`
- If a PMID is mentioned in the issue, ALWAYS try and read it
- ALWAYS check proposed parent terms for consistency

## Editors guide

### How to create new terms in OBA

#### Overview
- IMPORTANT: Do not edit the edit file directly, it's large
- OBA terms are compositional, check DOSDP design patterns: `src/patterns/dosdp-patterns/*.yaml`
- Desgin pattern templates are found in `src/patterns/data/default`

#### Steps

    1- Read the issue carefully to identify design pattern filler terms.

        Example:

            ```
            ```

    2- Check whether design pattern components have been imported to OBA. Search `src/ontology/imports/merged_import.owl`

    3- If they do, please proceed to creating the new OBA term using the appropriate DOSDP pattern template.

    4- Add the term to the template, then run 
            sh run.sh make IMP=false MIR=false ../patterns/definitions.owl 

    5- Refresh OBA imports by running
            sh run.sh make refresh-merged 

    6 - Run sh run.sh make IMP=false MIR=false ../patterns/definitions.owl again.

    7- When creating new OBA terms using DOSDP patterns, it may be necessary to import terms from other ontologies like ChEBI, the Chemical Entities of Biological Interest or PRO, the PRotein Ontology. However, they are too large to be managed as standard imports so are managed as slims. When a new term you are using in a DOSDP pattern is not yet in a slim you will have to refresh the slim first. They are located here:

        PRO: https://github.com/obophenotype/pro_obo_slim
        CHEBI: https://github.com/obophenotype/chebi_obo_slim

## OBO Format Guidelines
- Term ID format: OBA:NNNNNNN (7-digit number)
- Handling New Term Requests (NTRs):
  - New terms start OBA:210xxxx
  - Do `grep id: OBA:210 src/ontology/oba-edit.obo` to check for clashes
- Each term requires: id, name, definition with references
- Never guess OBA IDs, or ontology term IDs, use search tools above to determine actual term
- Never guess PMIDs for references, do a web search if needed
- Use standard relationship types: is_a, part_of, has_part, etc.
- Follow existing term patterns for consistency

## Publications
- Run the command `aurelian fulltext <PMID:nnn>` to fetch full text for a publication. A doi or URL can also be used
- You should cite publications appropriately, e.g. `def: "...." [PMID:nnnn, doi:mmmm]

## GitHub Contribution Process
- Most requests from users should follow one of two patterns:
    - You are not confident how to proceed, in which case end with asking a clarifying question (via `gh`)
    - You are confident how to proceed, you make changes, commit on a branch, and open a PR for the user to review
- Check existing terms before adding new ones
- For new terms: provide name, definition, place in hierarchy, and references
- Include PMIDs for all assertions
- Follow naming conventions from parent terms
- Always commit in a branch, e.g. issue-NNN
- If there is an existing PR which you started then checkout that branch and continue, rather than starting a new PR (unless you explicitly want to abandon the original PR, e.g. it was on completely the wrong tracks)
- Always make clear detailed commit messages, saying what you did and why
- Always sign your commits `@dragon-ai-agent`
- Create PRs using `gh pr create ...`
- File PRs with clear descriptions, and sign your PR

## Handling GitHub issues and requests
- Use `gh` to read and write issues/PRs
- Sign all commits and PRs as `@dragon-ai-agent`

## TROUBLESHOOTING
- If your obo file has syntax errors, you can use `robot convert -vvv` to see full trace

## Obsoleting terms originating from DOS-DP templates

- Delete the row with the targeted term from the appropriate data table (tsv file) in folder: src/patterns/data/default/
- Fill in the IRI of the term to be obsoleted in src/templates/obsoletes.tsv along with other relevant information. It is useful add a comment with an explanation for the obsoletion. Start the comment with 'Reason for obsoletion: '.
- Re-create the DOS-DP axioms by running

    cd PATH-TO/bio-attribute-ontology/src/ontology
    sh run.sh make ../patterns/definitions.owl
    sh run.sh make components/obsoletes.owl

        Example:

        ```
        [Term]

        ```

## Other metadata

- Link back to the issue you are dealing with using the `term_tracker_item`
- All terms should have definitions, with at least one definition xref, ideally a PMID
- You can sign terms as `created_by: dragon-ai-agent`

## Relationships

All terms should have at least one `is_a` (this can be implicit by a logical definition, see below).
The four main relationships used in OBA are `part_of`, `characteristic_of`, `characteristic_of_part_of`, and `subclass_of`. In addition, the relationship `has_role` is used in cases where the definition of a biological attribute requires a reference to a chemical role.

## Logical definitions

These should follow genus-differentia form, and depend on the pattern used. 

        Example:

        ```

        [Term]
        id: OBA:2040177
        name: level of ceramide
        def: "The amount of a ceramide when measured in anatomical entity." [AUTO:patterns/patterns/entity_attribute_location]
        synonym: "anatomical entity ceramide amount" EXACT [AUTO:patterns/patterns/entity_attribute_location]
        synonym: "ceramide amount" EXACT []
        is_a: OBA:1000965 ! sphingolipid level
        property_value: terms:contributor "https://orcid.org/0000-0001-8314-2140" xsd:string

        ```

The reasoner can find the most specific `is_a`, so it's OK to leave this off.
