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
# Steps 3-9: generated synonyms for amount traits. Their labels read
# "amount of X in Y"; two more forms are kept as exact synonyms so that a search
# phrased either way finds the term (EBISPOT/efo#2644, #443):
#   - the entity-first form "X amount in Y", written by the location patterns
#     themselves from their fillers' labels;
#   - the "level" form of the label ("level of X in Y", "X level"), derived here.
# Both are first written with an xref ending in "/generated". The steps below
# keep them only where they read correctly and clash with nothing, then drop the
# suffix so that they carry their pattern's usual AUTO xref.

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
#    temporary triple that step 9 removes again.
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

# 4. The entity-first form is only wanted on amount traits. The location
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

# 5. With the placeholder location the entity-first form ends in
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

# 6. The level form of the label, for every amount trait that lacks it:
#    "amount of X in Y" -> "level of X in Y", "X amount" -> "X level". It takes
#    the AUTO xref the term's other generated axioms carry.
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
      ?c <urn:oba:postprocess#amount-trait> true .
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

# 7. A generated synonym must not be shared: drop it where another term already
#    has the same string, ignoring case, as its label or as an exact synonym.
#    (ROBOT report fails on a shared exact synonym: duplicate_exact_synonym.)
#    The upper-cased strings are indexed as temporary triples first.
INSERT {
  ?e <urn:oba:postprocess#key> ?key .
}
WHERE {
  { ?e oboInOwl:hasExactSynonym ?v } UNION { ?e rdfs:label ?v }
  FILTER(isIRI(?e))
  BIND(UCASE(STR(?v)) AS ?key)
} ;

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
  BIND(UCASE(STR(?syn)) AS ?key)
  ?d <urn:oba:postprocess#key> ?key .
  FILTER(?d != ?c)
  ?ax ?axp ?axo .
} ;

# 8. Drop the "/generated" marker from the xrefs of the synonyms that are kept.
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

# 9. Remove the temporary triples of steps 3 and 7.
DELETE WHERE {
  ?c <urn:oba:postprocess#amount-trait> ?t .
} ;

DELETE WHERE {
  ?e <urn:oba:postprocess#key> ?k .
}
