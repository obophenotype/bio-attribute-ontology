## Customize Makefile settings for oba
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

# CORE is the edited source plus compiled modules
# EDIT 2021: seems to be what is now named OBA base

MAKE_FAST=$(MAKE) IMP=false PAT=false COMP=false MIR=false

dependencies:
	pip install -U pip
	pip install -U oaklib
	#pip install -U sssom
	pip install -U pip install git+https://github.com/mapping-commons/sssom-py.git@matentzn-patch-1

%.db: %.owl
	semsql make $@

#####################################################
### Overwrites for Imports and release artefacts ####
#####################################################

SL_PREFIXES="PREFIX skos: <http://www.w3.org/2004/02/skos/core\#> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema\#> PREFIX foaf: <http://xmlns.com/foaf/0.1/> PREFIX SLM: <https://swisslipids.org/rdf/SLM_> PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns\#> PREFIX owl: <http://www.w3.org/2002/07/owl\#>"

$(TMPDIR)/sl_haspart.sparql: $(IMPORTDIR)/swisslipids_terms.txt
	echo $(SL_PREFIXES) > $@
	echo "CONSTRUCT { ?s rdfs:subClassOf [ rdf:type owl:Restriction ; owl:onProperty <http://purl.obolibrary.org/obo/BFO_0000051> ; owl:someValuesFrom ?o ] } WHERE { VALUES ?s { " >> $@
	cat $< >> $@
	echo "} VALUES ?o {" >> $@ 
	cat $< >> $@
	echo "} GRAPH <https://sparql.swisslipids.org/swisslipids> { ?s SLM:hasPart+ ?o. } }" >> $@

$(TMPDIR)/sl_partof.sparql: $(IMPORTDIR)/swisslipids_terms.txt
	echo $(SL_PREFIXES) > $@
	echo "CONSTRUCT { ?s rdfs:subClassOf [ rdf:type owl:Restriction ; owl:onProperty <http://purl.obolibrary.org/obo/BFO_0000050> ; owl:someValuesFrom ?o ] } WHERE { VALUES ?s { " >> $@
	cat $< >> $@
	echo "} VALUES ?o {" >> $@ 
	cat $< >> $@
	echo "} GRAPH <https://sparql.swisslipids.org/swisslipids> { ?s SLM:partOf+ ?o. } }" >> $@

$(TMPDIR)/sl_subclassof.sparql: $(IMPORTDIR)/swisslipids_terms.txt
	echo $(SL_PREFIXES) > $@
	echo "CONSTRUCT { ?s rdfs:subClassOf ?o . ?o rdfs:label ?l . ?s rdfs:subClassOf ?eqs . ?o rdfs:subClassOf ?eqo . ?s skos:exactMatch ?eqs . ?o skos:exactMatch ?eqo . } WHERE { VALUES ?s { " >> $@
	cat $< >> $@
	echo "} GRAPH <https://sparql.swisslipids.org/swisslipids> { ?s rdfs:subClassOf+ ?o. ?o rdfs:label ?l . ?s owl:equivalentClass ?eqs . ?o owl:equivalentClass ?eqo . } }" >> $@

$(TMPDIR)/sl_subclasslipid.sparql: $(IMPORTDIR)/swisslipids_terms.txt
	echo $(SL_PREFIXES) > $@
	echo "CONSTRUCT { ?s rdfs:subClassOf <http://purl.obolibrary.org/obo/CHEBI_18059> . } WHERE { VALUES ?s { " >> $@
	cat $< >> $@
	echo "} GRAPH <https://sparql.swisslipids.org/swisslipids> { ?s rdfs:label ?l . } }" >> $@

$(TMPDIR)/sl_metadata.sparql: $(IMPORTDIR)/swisslipids_terms.txt
	echo $(SL_PREFIXES) > $@
	echo "CONSTRUCT { ?s ?p ?o. } WHERE { VALUES ?s { " >> $@
	cat $< >> $@
	echo "} VALUES ?p { <http://www.w3.org/2000/01/rdf-schema#seeAlso> <http://www.w3.org/2000/01/rdf-schema#label> <http://purl.obolibrary.org/obo/chebi/inchi> <http://purl.obolibrary.org/obo/chebi/formula> } GRAPH <https://sparql.swisslipids.org/swisslipids> { ?s ?p ?o. } }" >> $@

$(TMPDIR)/sl_%.ttl: $(TMPDIR)/sl_%.sparql
	$(eval SL_OL := $(shell tr '\n' ' ' < $< | sed 's/\#/\\#/g'))
	curl -L -H 'accept:text/turtle' 'https://beta.sparql.swisslipids.org/sparql/' \
		--data-urlencode 'query=$(SL_OL)' -o $@
	
SL_MODULES_IDS=subclassof metadata partof haspart subclasslipid
SL_MODULES = $(patsubst %, $(TMPDIR)/sl_%.ttl, $(SL_MODULES_IDS))

# The swisslipid mirror is basically assembled through a number of calls to the swisslipid sparql endpoint
# The weirdest thing is the way we treat subclass of here: if a swisslipid class is equivalent to a chebi class
# We make it a subclass of the Chebi class, but add a skos:exactMatch for reference
mirror/swisslipids.owl: $(SL_MODULES)
	$(ROBOT) merge $(patsubst %, -i %, $^) reason reduce convert  --output $@

$(MIRRORDIR)/lipidmaps.owl: $(TEMPLATEDIR)/lipidmaps.tsv
	if [ $(IMP) = true ] ; then $(ROBOT) template  \
		--prefix "LM: https://bioregistry.io/lipidmaps:" \
		$(patsubst %, --template %, $^) \
		$(ANNOTATE_CONVERT_FILE); fi

# FULL is overwritten because it needs materialize
$(ONT)-full.owl: $(SRC) $(OTHER_SRC)
	echo "INFO: Running FULL release, which is customised for OBA."
	$(ROBOT) merge --input $< \
		reason --reasoner ELK --equivalent-classes-allowed asserted-only --exclude-tautologies structural \
		remove --term PR:000000001 \
			   --term SO:0000252 \
			   --term SO:0000234 \
		reason --reasoner ELK --equivalent-classes-allowed none --exclude-tautologies structural \
		relax \
		reduce -r ELK \
		materialize -T basic_properties.txt \
		reduce -r ELK \
		$(SHARED_ROBOT_COMMANDS) annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@

# Synonyms are managed on Google Sheets
OBA_SYNONYM_TEMPLATE=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=473147169&single=true&output=tsv

../templates/synonyms.tsv:
	if [ $(COMP) = true ]; then wget "$(OBA_SYNONYM_TEMPLATE)" -O $@; fi

.PHONY: sync_templates_google_sheets
sync_templates_google_sheets:
	$(MAKE) ../templates/measured_in.tsv -B
	$(MAKE) ../templates/synonyms.tsv -B

###########################
### GH Release ############
###########################

# Remove this, this was added to ODK!
RELEASE_ASSETS_AFTER_RELEASE=$(foreach n,$(RELEASE_ASSETS), ../../$(n))
GHVERSION=v$(VERSION)

.PHONY: public_release
public_release:
	@test $(GHVERSION)
	ls -alt $(RELEASE_ASSETS_AFTER_RELEASE)
	gh release create $(GHVERSION) --title "$(VERSION) Release" --draft $(RELEASE_ASSETS_AFTER_RELEASE) --generate-notes

#######################################################
#### Automated OBA Alignment Pipeline: Templates ######
########################################################

OBA_EFO_GS=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=1005741851&single=true&output=tsv
OBA_VT_GS=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=506793298&single=true&output=tsv
OBA_EFO_EXCLUSIONS_GS=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=698990842&single=true&output=tsv
OBA_VT_EXCLUSIONS_GS=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=2051840457&single=true&output=tsv

../mappings/oba-efo.sssom.tsv:
	wget "$(OBA_EFO_GS)" -O $@

../mappings/oba-vt.sssom.tsv:
	wget "$(OBA_VT_GS)" -O $@

../mappings/oba-efo-mapping-exclusions.sssom.tsv:
	wget "$(OBA_EFO_EXCLUSIONS_GS)" -O $@

../mappings/oba-vt-mapping-exclusions.sssom.tsv:
	wget "$(OBA_VT_EXCLUSIONS_GS)" -O $@

.PHONY: sync_sssom_google_sheets
sync_sssom_google_sheets:
	$(MAKE) ../mappings/oba-efo.sssom.tsv -B
	$(MAKE) ../mappings/oba-vt.sssom.tsv -B
	$(MAKE) ../mappings/oba-efo-mapping-exclusions.sssom.tsv -B
	$(MAKE) ../mappings/oba-vt-mapping-exclusions.sssom.tsv -B

##################################
### Custom QC checks #############
##################################

$(TMPDIR)/oba.owl: $(SRC)
	$(ROBOT) merge -i $< -o $@
.PRECIOUS: $(TMPDIR)/oba.owl

CHECK_SPARQL=oba.owl

check_children_oba: $(CHECK_SPARQL)
	$(ROBOT) verify -i $< --queries ../sparql/biological-attribute-child-violation.sparql -O $(REPORTDIR)

test: check_children_oba

##################################
### Synchronisation pipeline #####
##################################

$(TMPDIR)/mirror-%.owl:
	wget $(OBOBASE)/$*.owl -O $@
.PRECIOUS: $(TMPDIR)/mirror-%.owl

EFO=http://www.ebi.ac.uk/efo/efo.owl

$(TMPDIR)/efo-dl.owl:
	wget $(EFO) -O $@
.PRECIOUS: $(TMPDIR)/efo-dl.owl

$(TMPDIR)/mirror-efo.owl: $(TMPDIR)/efo-dl.owl
	$(ROBOT) merge -i $< filter --term "http://www.ebi.ac.uk/efo/EFO_0001444" --select "self descendants" --trim false -o $@
.PRECIOUS: $(TMPDIR)/efo.owl

$(REPORTDIR)/oba-alignment-%.tsv: ../sparql/synonyms-exact.sparql $(TMPDIR)/mirror-%.owl
	$(ROBOT) query -i $(TMPDIR)/mirror-$*.owl --use-graphs true --query ../sparql/synonyms-exact.sparql $@
.PRECIOUS: $(REPORTDIR)/oba-alignment-%.tsv

.PHONY: prepare_oba_alignment
prepare_oba_alignment: 
	$(MAKE) $(REPORTDIR)/oba-alignment-uberon.tsv \
		$(REPORTDIR)/oba-alignment-efo.tsv $(REPORTDIR)/oba-alignment-pato.tsv \
		$(REPORTDIR)/oba-alignment-oba.tsv $(REPORTDIR)/oba-alignment-vt.tsv \
		$(REPORTDIR)/oba-alignment-cl.tsv $(REPORTDIR)/oba-alignment-go.tsv \
		$(REPORTDIR)/oba-alignment-chebi.tsv
	echo "OK cool all tables prepared."

#########################
## Custom reports #######
#########################

.PHONY: oba_reports
oba_reports: $(CHECK_SPARQL)
	sh run.sh robot query -i $< \
		--query ../sparql/oba-pato-report.sparql reports/oba-pato.csv \
		--query ../sparql/oba-grouping-report.sparql reports/oba-grouping.csv

#######################################
#### Custom Dynamic Documentation #####
#######################################

DOCUMENTATION_PAGES=../../docs/metrics.md \
					../../docs/oak-metrics.md \
					../../docs/robot-metrics.md

reports/robot-metrics.yml: oba-baseplus.owl
	$(ROBOT) measure -i $< --format yaml --metrics all -o $@

reports/oak-metrics.yml: oba-baseplus.db
	runoak -i $< statistics --has-prefix OBA > $@

../../docs/%-metrics.md: config/%-metrics.md.jinja2 reports/%-metrics.yml
	j2 $^ > $@

../../docs/metrics.md:
	echo "# Metrics" > $@
	echo "" >> $@
	echo "There are currently two sets of metrics of this ontology:" >> $@
	echo "" >> $@
	echo "* [ROBOT metrics](robot-metrics.md)" >> $@
	echo "* [ROBOT metrics](oak-metrics.md)" >> $@

.PHONY: documentation
documentation: 
	$(MAKE_FAST) $(DOCUMENTATION_PAGES)

#######################################
#### OAK DIFF ANALYSIS ################
#######################################
# Here, we compare the structure of OAK with other ontologies

$(TMPDIR)/vt-baseplus.owl: $(TMPDIR)/mirror-vt.owl
	$(ROBOT_RELEASE_IMPORT_MODE) \
	reason --reasoner ELK --equivalent-classes-allowed asserted-only --exclude-tautologies structural \
	relax \
	reduce -r ELK \
	remove --base-iri $(URIBASE)/VT --axioms external --preserve-structure false --trim false \
	$(SHARED_ROBOT_COMMANDS) \
	annotate --link-annotation http://purl.org/dc/elements/1.1/type http://purl.obolibrary.org/obo/IAO_8000001 \
		--ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
		--output $@.tmp.owl && mv $@.tmp.owl $@

$(REPORTDIR)/oba-vt-diff-simple.yaml: oba-baseplus.owl $(TMPDIR)/vt-baseplus.owl
	runoak --input sqlite:$< diff-via-mappings -X sqlite:$(TMPDIR)/vt-baseplus.owl --mapping-input ../mappings/oba-vt.sssom.tsv -o $@

.PHONY: oak_diff
oak_diff: 
	$(MAKE_FAST) $(REPORTDIR)/oba-vt-diff-simple.yaml

###########################################
#### OAK Matching Pipeline ################
###########################################

curation/protein-pr-matches.tsv: curation/protein-2023-05-19.txt
	sed -e 's/measurement//g' $< > tmp/matches.txt
	runoak  --stacktrace --input sqlite:obo:pr annotate --matches-whole-text --text-file tmp/matches.txt -O csv -o $@

curation/protein-oba-matches.tsv: curation/protein-2023-05-19.txt
	sed -e 's/measurement//g' $< > tmp/matches.txt
	runoak  --stacktrace --input sqlite:obo:oba annotate --matches-whole-text --text-file tmp/matches.txt -O csv -o $@

curation/protein-gilda-matches.tsv: curation/protein-2023-05-19.txt
	sed -e 's/measurement//g' $< > tmp/matches.txt
	runoak  --stacktrace --input gilda: annotate --matches-whole-text --text-file tmp/matches.txt -O csv -o $@

curation/protein-bioportal-matches.tsv: curation/protein-2023-05-19.txt
	sed -e 's/measurement//g' $< > tmp/matches.txt
	runoak  --stacktrace --input bioportal: annotate --matches-whole-text --text-file tmp/matches.txt -O csv -o $@

.PHONY: protein-matches

protein-matches:
	$(MAKE) curation/protein-bioportal-matches.tsv
	$(MAKE) curation/protein-gilda-matches.tsv
	$(MAKE) curation/protein-oba-matches.tsv
	$(MAKE) curation/protein-pr-matches.tsv


curation/impc-matches.txt:
	runoak annotate --text-file curation/impc-traits-2022-12-01.txt -o curation/impc-matches.txt sqlite:oba.owl

$(TMPDIR)/lexmatch-%.sssom.tsv: $(TMPDIR)/mirror-%.db
	runoak -i $< lexmatch -o $@

.PHONY: oak_match
oak_match: 
	$(MAKE_FAST) curation/impc-matches.txt
	$(MAKE_FAST) $(TMPDIR)/lexmatch-vt.sssom.tsv
	$(MAKE_FAST) $(TMPDIR)/lexmatch-efo.sssom.tsv

############################################
### Phenotype Ontology Mappings ############
############################################

$(TMPDIR)/mirror-base-hp.owl:
	wget $(OBOBASE)/hp/hp-base.owl -O $@
.PRECIOUS: $(TMPDIR)/mirror-base-hp.owl

$(TMPDIR)/mirror-base-zp.owl:
	wget $(OBOBASE)/zp/zp-base.owl -O $@
.PRECIOUS: $(TMPDIR)/mirror-base-zp.owl

$(TMPDIR)/mirror-base-xpo.owl:
	wget $(OBOBASE)/xpo/xpo-base.owl -O $@
.PRECIOUS: $(TMPDIR)/mirror-base-xpo.owl

$(TMPDIR)/mirror-base-mp.owl:
	wget $(OBOBASE)/mp/mp-base.owl -O $@
.PRECIOUS: $(TMPDIR)/mirror-base-mp.owl

PHENOTYPE_IDS = mp hp zp xpo
PHENOTYPE_BASES = $(patsubst %, $(TMPDIR)/mirror-base-%.owl, $(PHENOTYPE_IDS))

$(TMPDIR)/mirror-all.owl: $(MIRRORDIR)/merged.owl $(PHENOTYPE_BASES)
	$(ROBOT) merge $(patsubst %, -i %, $^) -o $@
.PRECIOUS: $(TMPDIR)/mirror-all.owl

qqq:
	$(MAKE_FAST) $(TMPDIR)/mirror-all.owl

#basebase:
#	$(MAKE_FAST) tmp/mirror-all.owl

##### CONTINUE FROM HERE, MERGE ALL THIS AND CREATE SSSOM FILES

$(TMPDIR)/oba-%.owl: $(TMPDIR)/mirror-%.owl oba-base.owl
	$(ROBOT) merge $(patsubst %, -i %, $^) \
		reason materialize --term BFO:0000051 -o $@
.PRECIOUS: $(TMPDIR)/oba-%.owl

$(TMPDIR)/oba-rg-%.owl: $(TMPDIR)/oba-%.owl
	relation-graph --ontology-file $< \
		--property 'http://purl.obolibrary.org/obo/BFO_0000051' \
		--output-file $(TMPDIR)/relations.ttl --mode rdf
	$(ROBOT) merge -i $< -i $(TMPDIR)/relations.ttl \
		reduce --reasoner ELK --named-classes-only true -o $@
.PRECIOUS: $(TMPDIR)/oba-rg-%.owl

$(TMPDIR)/oba-rg-%.json: $(TMPDIR)/oba-rg-%.owl
	$(ROBOT) convert -i $< -f json -o $@
.PRECIOUS: $(TMPDIR)/oba-rg-%.json

../mappings/oba-%-phenotype.sssom.tsv: $(TMPDIR)/oba-rg-%.json
	sssom parse $(TMPDIR)/oba-rg-$*.json -I obographs-json -C merged -m config/oba.sssom.config.yml -F BFO:0000051 -o $@
.PRECIOUS: ../mappings/oba-%-phenotype.sssom.tsv

.PHONY: phenotype_mappings
phenotype_mappings: 
	#$(MAKE_FAST) ../mappings/oba-mp-phenotype.sssom.tsv
	#$(MAKE_FAST) ../mappings/oba-hp-phenotype.sssom.tsv
	$(MAKE_FAST) ../mappings/oba-all-phenotype.sssom.tsv
	grep -E "HP:.*OBA:" ../mappings/oba-all-phenotype.sssom.tsv | wc -l
	grep -E "ZP:.*OBA:" ../mappings/oba-all-phenotype.sssom.tsv | wc -l
	grep -E "MP:.*OBA:" ../mappings/oba-all-phenotype.sssom.tsv | wc -l
	grep -E "XPO:.*OBA:" ../mappings/oba-all-phenotype.sssom.tsv | wc -l
	grep -Eo "MP:[0-9]+" ../mappings/oba-all-phenotype.sssom.tsv | sort | uniq | wc -l
	grep -Eo "HP:[0-9]+" ../mappings/oba-all-phenotype.sssom.tsv | sort | uniq | wc -l
	grep -Eo "ZP:[0-9]+" ../mappings/oba-all-phenotype.sssom.tsv | sort | uniq | wc -l
	grep -Eo "XPO:[0-9]+" ../mappings/oba-all-phenotype.sssom.tsv | sort | uniq | wc -l


tmp/pato.owl:
	wget "http://purl.obolibrary.org/obo/pato.owl" -O $@

../mappings/pato_attribute_value.csv: tmp/pato.owl ../sparql/pato-attribute-value-map.sparql
	$(ROBOT) query -i $< --query ../sparql/pato-attribute-value-map.sparql $@

prepare_release: ../mappings/pato_attribute_value.sssom.tsv

../mappings/pato_attribute_value.sssom.tsv: tmp/pato.owl ../sparql/pato-attribute-value-map.sparql
	$(ROBOT) query -i $< --format ttl --query ../sparql/pato-attribute-value-map.ru tmp/construct_pato_attribute.ttl
	$(ROBOT) annotate -i tmp/construct_pato_attribute.ttl --ontology-iri "http://purl.obolibrary.org/obo/pato/mappings.owl" convert -f json -o tmp/construct_pato_attribute.json
	sssom parse tmp/construct_pato_attribute.json -I obographs-json -C merged -m config/oba.sssom.config.yml -o $@ 
	sssom annotate $@ --mapping_set_id "http://purl.obolibrary.org/obo/oba/mappings/pato_attribute_value.sssom.tsv" --mapping_date $(TODAY) --subject_source http://purl.obolibrary.org/obo/pato.owl --object_source http://purl.obolibrary.org/obo/pato.owl -o $@ 

$(TMPDIR)/base_unsat.md: $(TMPDIR)/mirror-all.owl 
	$(ROBOT) explain -i $< -M unsatisfiability --unsatisfiable random:10 --explanation $@

.PHONY: base_unsat
base_unsat: 
	$(MAKE_FAST) $(TMPDIR)/base_unsat.md


EXPLAIN_ONE=GO:0005737
EXPLAIN_TWO=GO:0099568
explain_equivalent:
	$(ROBOT) merge --input oba-edit.obo  -i components/reasoner_axioms.owl \
		explain --reasoner ELK \
  		--axiom "$(EXPLAIN_ONE) EquivalentTo $(EXPLAIN_TWO)" \
  		--explanation $(TMPDIR)/explain_equivalent.md

##################################
##### Utilities ###################
##################################

.PHONY: help
help:
	@echo "$$data"
	echo "* sync_templates_google_sheet:	Synchronise ROBOT templates from OBA Google Sheet"
	echo "* sync_sssom_google_sheets:		Synchronise SSSOM Mappings from OBA Google Sheet (alignment pipeline)"
	echo "* prepare_oba_alignment:			Prepare all files needed for Running the OBA alignment pipeline"
	echo "* oba_reports:					Generate some OBA specific reports"
	echo "* documentation:					Generate OBA-specific dynamic documentation"
	echo "* oak_diff:						Generate some OBA specific reports"
	echo "* oak_match:						Run a bunch of standard OAK matching tasks"
	echo "* phenotype_mappings:				Recreate the OBA Phenotype mappings"

