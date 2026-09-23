# Post-processing for the DOSDP-generated patterns/definitions.owl.
#
# The entity_attribute_location pattern requires a location. A number of
# generic "amount / level" terms (proteins, chemicals) are generated with the
# root class 'anatomical entity' (UBERON:0001062) as a placeholder location.
# This produces an awkward definition ("... when measured in anatomical entity")
# and a meaningless exact synonym ("anatomical entity X amount"). This update
# removes both artefacts. The (harmless) logical axiom is intentionally left
# untouched. See https://github.com/obophenotype/bio-attribute-ontology/issues/439

PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>

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
}
