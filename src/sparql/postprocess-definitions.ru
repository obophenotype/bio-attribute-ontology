# Post-processing for the DOSDP-generated patterns/definitions.owl.
#
# Steps 1-2: the entity_attribute_location pattern requires a location. A number of
# generic "amount / level" terms (proteins, chemicals) are generated with the
# root class 'anatomical entity' (UBERON:0001062) as a placeholder location.
# This produces an awkward definition ("... when measured in anatomical entity")
# and a meaningless exact synonym ("anatomical entity X amount"). This update
# removes both artefacts. The (harmless) logical axiom is intentionally left
# untouched. See https://github.com/obophenotype/bio-attribute-ontology/issues/439
#
# Steps 3-10: synonyms of amount traits. Their labels read "amount of X in Y";
# three more forms are kept as exact synonyms (EBISPOT/efo#2644, #443):
#   - the entity-first form "X amount in Y", written by the location patterns
#     themselves from their fillers' labels;
#   - the level form of the label ("level of X in Y", "X level"), derived here
#     for chemical and protein fillers only ("ulna level" is not a way of
#     saying "ulna amount");
#   - the former label of a relabelled term, curated in the patterns'
#     previous_label column and typed here as OMO:0003000 "previous name".
# The first two are written with an xref ending in "/generated", the third with
# the xref "AUTO:previous_label"; the steps below settle them. A generated
# synonym that clashes with another term's label or synonym is deliberately
# left in place: ROBOT report then fails the build (duplicate_exact_synonym),
# which is right, as such a clash means two terms should be merged.

PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

# 1. Strip " when measured in anatomical entity" from the text definition
#    (updating the reified annotation axiom that carries the AUTO xref too).
DELETE {
  ?c obo:IAO_0000115 ?def .
  ?ax owl:annotatedTarget ?def .
}
INSERT {
  ?c obo:IAO_0000115 ?newdef .
  ?ax owl:annotatedTarget ?newdef .
}
WHERE {
  ?c obo:IAO_0000115 ?def .
  ?ax rdf:type owl:Axiom ;
      owl:annotatedSource ?c ;
      owl:annotatedProperty obo:IAO_0000115 ;
      owl:annotatedTarget ?def ;
      oboInOwl:hasDbXref "AUTO:patterns/patterns/entity_attribute_location" .
  FILTER(CONTAINS(STR(?def), " when measured in anatomical entity"))
  BIND(STRDT(REPLACE(STR(?def), " when measured in anatomical entity", ""), xsd:string) AS ?newdef)
} ;

# 2. Delete the pattern-generated exact synonyms that use the placeholder
#    'anatomical entity' location prefix (e.g. "anatomical entity X amount"),
#    together with their reified annotation axiom.
DELETE {
  ?c oboInOwl:hasExactSynonym ?syn .
  ?ax ?axp ?axo .
}
WHERE {
  ?c oboInOwl:hasExactSynonym ?syn .
  ?ax rdf:type owl:Axiom ;
      owl:annotatedSource ?c ;
      owl:annotatedProperty oboInOwl:hasExactSynonym ;
      owl:annotatedTarget ?syn ;
      oboInOwl:hasDbXref "AUTO:patterns/patterns/entity_attribute_location" .
  FILTER(STRSTARTS(STR(?syn), "anatomical entity "))
  ?ax ?axp ?axo .
} ;

# 3. Tag the amount traits (genus PATO:0000070 as the first or second operand
#    of the equivalence, which is how every pattern writes it) once, with a
#    temporary triple that step 10 removes again.
INSERT {
  ?c <urn:oba:postprocess#amount-trait> true .
}
WHERE {
  ?c owl:equivalentClass ?e .
  ?e owl:intersectionOf ?list .
  { ?list rdf:first obo:PATO_0000070 }
  UNION
  { ?list rdf:rest/rdf:first obo:PATO_0000070 }
  FILTER(isIRI(?c))
} ;

# 4. Tag, among them, the traits whose filler is a chemical or protein: a
#    named class from ChEBI, PRO, SwissLipids or LIPID MAPS anywhere in the
#    intersection tree of the 'characteristic_of' filler (the patterns nest
#    it differently). Only these get the level form (step 7).
INSERT {
  ?c <urn:oba:postprocess#chemical-filler> true .
}
WHERE {
  ?c <urn:oba:postprocess#amount-trait> true .
  ?c owl:equivalentClass ?e .
  ?e owl:intersectionOf ?list .
  { ?list rdf:first ?r }
  UNION
  { ?list rdf:rest/rdf:first ?r }
  ?r owl:onProperty obo:RO_0000052 ;
     owl:someValuesFrom ?f .
  ?f (owl:intersectionOf/rdf:rest*/rdf:first)* ?m .
  FILTER(isIRI(?m))
  FILTER(STRSTARTS(STR(?m), "http://purl.obolibrary.org/obo/CHEBI_")
      || STRSTARTS(STR(?m), "http://purl.obolibrary.org/obo/PR_")
      || STRSTARTS(STR(?m), "https://swisslipids.org/rdf/SLM_")
      || STRSTARTS(STR(?m), "https://bioregistry.io/lipidmaps:"))
} ;

# 5. The entity-first form is only wanted on amount traits. The location
#    patterns also carry a few other attributes ("concentration of",
#    "susceptibility toward", ...) for which it does not read.
DELETE {
  ?c oboInOwl:hasExactSynonym ?syn .
  ?ax ?axp ?axo .
}
WHERE {
  ?ax rdf:type owl:Axiom ;
      owl:annotatedSource ?c ;
      owl:annotatedProperty oboInOwl:hasExactSynonym ;
      owl:annotatedTarget ?syn ;
      oboInOwl:hasDbXref ?x .
  FILTER(STRENDS(STR(?x), "/generated"))
  FILTER NOT EXISTS { ?c <urn:oba:postprocess#amount-trait> true }
  ?ax ?axp ?axo .
} ;

# 6. With the placeholder location the entity-first form ends in
#    " in anatomical entity"; drop that part. Where what is left is already the
#    label or a synonym of the term, drop the generated synonym instead.
DELETE {
  ?c oboInOwl:hasExactSynonym ?syn .
  ?ax ?axp ?axo .
}
WHERE {
  ?ax rdf:type owl:Axiom ;
      owl:annotatedSource ?c ;
      owl:annotatedProperty oboInOwl:hasExactSynonym ;
      owl:annotatedTarget ?syn ;
      oboInOwl:hasDbXref ?x .
  FILTER(STRENDS(STR(?x), "/generated"))
  FILTER(STRENDS(STR(?syn), " in anatomical entity"))
  BIND(STRDT(SUBSTR(STR(?syn), 1, STRLEN(STR(?syn)) - STRLEN(" in anatomical entity")), xsd:string) AS ?short)
  FILTER(EXISTS { ?c rdfs:label ?short } || EXISTS { ?c oboInOwl:hasExactSynonym ?short })
  ?ax ?axp ?axo .
} ;

DELETE {
  ?c oboInOwl:hasExactSynonym ?syn .
  ?ax owl:annotatedTarget ?syn .
}
INSERT {
  ?c oboInOwl:hasExactSynonym ?short .
  ?ax owl:annotatedTarget ?short .
}
WHERE {
  ?ax rdf:type owl:Axiom ;
      owl:annotatedSource ?c ;
      owl:annotatedProperty oboInOwl:hasExactSynonym ;
      owl:annotatedTarget ?syn ;
      oboInOwl:hasDbXref ?x .
  FILTER(STRENDS(STR(?x), "/generated"))
  FILTER(STRENDS(STR(?syn), " in anatomical entity"))
  BIND(STRDT(SUBSTR(STR(?syn), 1, STRLEN(STR(?syn)) - STRLEN(" in anatomical entity")), xsd:string) AS ?short)
} ;

# 7. The level form of the label, for every chemical or protein amount trait
#    that lacks it: "amount of X in Y" -> "level of X in Y", "X amount" ->
#    "X level". It takes the AUTO xref the term's other generated axioms carry.
INSERT {
  ?c oboInOwl:hasExactSynonym ?lsyn .
  _:ax rdf:type owl:Axiom ;
       owl:annotatedSource ?c ;
       owl:annotatedProperty oboInOwl:hasExactSynonym ;
       owl:annotatedTarget ?lsyn ;
       oboInOwl:hasDbXref ?mark .
}
WHERE {
  {
    SELECT ?c (SAMPLE(?x) AS ?auto)
    WHERE {
      ?c <urn:oba:postprocess#chemical-filler> true .
      ?a owl:annotatedSource ?c ;
         oboInOwl:hasDbXref ?x .
      FILTER((STRSTARTS(STR(?x), "AUTO:patterns/") || STRSTARTS(STR(?x), "oba:patterns/"))
             && !STRENDS(STR(?x), "/generated"))
    }
    GROUP BY ?c
  }
  ?c rdfs:label ?label .
  FILTER(REGEX(STR(?label), "(^| )amount( |$)"))
  BIND(STRDT(REPLACE(STR(?label), "(^| )amount( |$)", "$1level$2"), xsd:string) AS ?lsyn)
  BIND(STRDT(CONCAT(STR(?auto), "/generated"), xsd:string) AS ?mark)
  FILTER NOT EXISTS { ?c oboInOwl:hasExactSynonym ?lsyn }
} ;

# 8. Former labels: the patterns write the previous_label column as exact
#    synonyms with the xref "AUTO:previous_label". Replace that marker by the
#    synonym type OMO:0003000 "previous name", and declare the type (ROBOT
#    report: missing_synonymtype_declaration).
DELETE {
  ?ax oboInOwl:hasDbXref ?marker .
}
INSERT {
  ?ax oboInOwl:hasSynonymType obo:OMO_0003000 .
}
WHERE {
  ?ax rdf:type owl:Axiom ;
      owl:annotatedProperty oboInOwl:hasExactSynonym ;
      oboInOwl:hasDbXref ?marker .
  FILTER(STR(?marker) = "AUTO:previous_label")
} ;

INSERT DATA {
  obo:OMO_0003000 rdf:type owl:AnnotationProperty ;
      rdfs:subPropertyOf oboInOwl:SynonymTypeProperty ;
      rdfs:label "previous name" .
  oboInOwl:SynonymTypeProperty rdf:type owl:AnnotationProperty .
  oboInOwl:hasSynonymType rdf:type owl:AnnotationProperty .
} ;

# 9. Drop the "/generated" marker from the xrefs of the synonyms that are kept.
DELETE {
  ?ax oboInOwl:hasDbXref ?x .
}
INSERT {
  ?ax oboInOwl:hasDbXref ?base .
}
WHERE {
  ?ax rdf:type owl:Axiom ;
      oboInOwl:hasDbXref ?x .
  FILTER(STRENDS(STR(?x), "/generated"))
  BIND(STRDT(SUBSTR(STR(?x), 1, STRLEN(STR(?x)) - STRLEN("/generated")), xsd:string) AS ?base)
} ;

# 10. Remove the temporary triples of steps 3 and 4.
DELETE WHERE {
  ?c <urn:oba:postprocess#amount-trait> ?t .
} ;

DELETE WHERE {
  ?c <urn:oba:postprocess#chemical-filler> ?t .
}
