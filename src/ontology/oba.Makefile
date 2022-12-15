## Customize Makefile settings for oba
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

# CORE is the edited source plus compiled modules
# EDIT 2021: seems to be what is now named OBA base
oba-core.owl: oba-base.owl
	cp $< $@

oba-core.obo: oba-base.obo
	cp $< $@

subsets/oba-basic.owl: oba-basic.owl
	cp $< $@
subsets/oba-basic.obo: oba-basic.obo
	cp $< $@

$(ONT)-full.owl: $(SRC) $(OTHER_SRC)
	$(ROBOT) merge --input $< \
		merge -i components/reasoner_axioms.owl \
		materialize -T basic_properties.txt \
		reason --reasoner ELK --equivalent-classes-allowed all --exclude-tautologies structural \
		relax \
		reduce -r ELK \
		unmerge -i components/reasoner_axioms.owl \
		$(SHARED_ROBOT_COMMANDS) annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@

.PRECIOUS: $(EDIT_PREPROCESSED)

base: $(EDIT_PREPROCESSED)
	$(ROBOT) merge --input $(EDIT_PREPROCESSED) \
	reason --reasoner ELK --equivalent-classes-allowed asserted-only --exclude-tautologies structural \
	relax \
	reduce -r ELK \
	remove --base-iri $(URIBASE)/OBA --axioms external --preserve-structure true --trim false \
	$(SHARED_ROBOT_COMMANDS) \
	annotate --link-annotation http://purl.org/dc/elements/1.1/type http://purl.obolibrary.org/obo/IAO_8000001 \
		--ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
		--output $@.owl

# ----------------------------------------
# VT
# ----------------------------------------

# TODO: The VT synchronisation pipeline does not work currently
vt.obo:
	wget $(URIBASE)/vt.obo -O $@

# ----------------------------------------
# DESIGN PATTERNS AND TEMPLATES
# ----------------------------------------

MODS = entity_attribute entity_attribute_location attribute_location

# VT is isolated to prevent isa-poisoning
modules/has_part.csv:  $(patsubst %, ../patterns/data/default/%.tsv, $(MODS))
	./util/make-vt-equiv-tsv.pl $^ > $@

# uses expression-materializing reasoner to infer superclasses and super parent expressions;
#modules/existential-graph.owl: oba-core.owl
#	$(OWLTOOLS) $< --merge-support-ontologies --reasoner elk --silence-elk --materialize-gcis --reasoner mexr --remove-redundant-inferred-svfs --reasoner elk --remove-redundant-svfs  --set-ontology-id $(URIBASE)/oba/$@ -o $@


## Customize Makefile settings for maxo
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

imports/hp_import.owl: $(TEMPLATEDIR)/external.owl
	$(ROBOT) merge -i $< annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) -o $@

$(IMPORTDIR)/mondo_import.owl: $(MIRRORDIR)/mondo.owl $(IMPORTDIR)/mondo_terms_combined.txt
	if [ $(IMP) = true ]; then $(ROBOT) query -i $< --update ../sparql/preprocess-module.ru \
		extract -T $(IMPORTDIR)/mondo_terms_combined.txt --force true --copy-ontology-annotations true --individuals exclude --method BOT \
		remove --select "<http://purl.obolibrary.org/obo/CP_*>" \
		query --update ../sparql/inject-subset-declaration.ru --update ../sparql/inject-synonymtype-declaration.ru --update ../sparql/postprocess-module.ru \
		annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@; fi

mirror-hp:
	echo "See oba.Makefile: No mirror needed, HPO generated from template."

test: pattern_schema_checks

RELEASE_ASSETS_RELEASE_DIR=$(foreach n,$(RELEASE_ASSETS), ../../$(n))
GHVERSION=v$(VERSION)

.PHONY: public_release
public_release:
	@test $(GHVERSION)
	ls -alt $(RELEASE_ASSETS_RELEASE_DIR)
	gh release create $(GHVERSION) --title "$(VERSION) Release" --draft $(RELEASE_ASSETS_RELEASE_DIR)  --generate-notes


#### Mappings

OBA_EFO_GS=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=1005741851&single=true&output=tsv
OBA_VT_GS=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=506793298&single=true&output=tsv
OBA_EFO_EXCLUSIONS_GS=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=698990842&single=true&output=tsv
OBA_VT_EXCLUSIONS_GS=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=2051840457&single=true&output=tsv
OBA_SYNONYM_TEMPLATE=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=473147169&single=true&output=tsv
OBA_MEASURED_IN_TEMPLATE=https://docs.google.com/spreadsheets/d/e/2PACX-1vSfh18vZmG6xXrknmklcEIlNnHqte598aFMczdm6SpYXVdnFL2iBthAA-z11s7bBR3s2kaf_d3XahrI/pub?gid=1857133171&single=true&output=tsv

../templates/synonyms.tsv:
	wget "$(OBA_SYNONYM_TEMPLATE)" -O $@

../templates/measured_in.tsv:
	wget "$(OBA_MEASURED_IN_TEMPLATE)" -O $@

../mappings/oba-efo.sssom.tsv:
	wget "$(OBA_EFO_GS)" -O $@

../mappings/oba-vt.sssom.tsv:
	wget "$(OBA_VT_GS)" -O $@

../mappings/oba-efo-mapping-exclusions.sssom.tsv:
	wget "$(OBA_EFO_EXCLUSIONS_GS)" -O $@

../mappings/oba-vt-mapping-exclusions.sssom.tsv:
	wget "$(OBA_VT_EXCLUSIONS_GS)" -O $@

sync_sssom_google_sheets:
	$(MAKE) ../mappings/oba-efo.sssom.tsv -B
	$(MAKE) ../mappings/oba-vt.sssom.tsv -B
	$(MAKE) ../mappings/oba-efo-mapping-exclusions.sssom.tsv -B
	$(MAKE) ../mappings/oba-vt-mapping-exclusions.sssom.tsv -B

sync_templates_google_sheets:
	$(MAKE) ../templates/measured_in.tsv -B
	$(MAKE) ../templates/synonyms.tsv -B

EFO=http://www.ebi.ac.uk/efo/efo.owl

$(TMPDIR)/%.owl:
	wget http://purl.obolibrary.org/obo/$*.owl -O $@
.PRECIOUS: $(TMPDIR)/%.owl

$(TMPDIR)/efo-dl.owl:
	wget $(EFO) -O $@
.PRECIOUS: $(TMPDIR)/efo-dl.owl

$(TMPDIR)/efo.owl: $(TMPDIR)/efo-dl.owl
	$(ROBOT) merge -i $< filter --term "http://www.ebi.ac.uk/efo/EFO_0001444" --select "self descendants" --trim false -o $@
.PRECIOUS: $(TMPDIR)/efo.owl

$(TMPDIR)/oba.owl: $(SRC)
	$(ROBOT) merge -i $< -o $@
.PRECIOUS: $(TMPDIR)/oba.owl

$(REPORTDIR)/%.tsv: ../sparql/synonyms-exact.sparql $(TMPDIR)/%.owl
	$(ROBOT) query -i $(TMPDIR)/$*.owl --use-graphs true --query ../sparql/synonyms-exact.sparql $@
.PRECIOUS: $(REPORTDIR)/%.tsv

prepare_oba_alignment: $(REPORTDIR)/uberon.tsv $(REPORTDIR)/efo.tsv $(REPORTDIR)/pato.tsv $(REPORTDIR)/oba.tsv $(REPORTDIR)/vt.tsv $(REPORTDIR)/cl.tsv $(REPORTDIR)/go.tsv $(REPORTDIR)/chebi.tsv
	echo "OK cool all tables prepared."

CHECK_SPARQL=$(TMPDIR)/oba.owl

check_children_oba: $(CHECK_SPARQL)
	$(ROBOT) verify -i $< --queries ../sparql/biological-attribute-child-violation.sparql -O $(REPORTDIR)

test: check_children_oba

oba_reports: $(CHECK_SPARQL)
	sh run.sh robot query -i $< \
		--query ../sparql/oba-pato-report.sparql reports/oba-pato.csv \
		--query ../sparql/oba-grouping-report.sparql reports/oba-grouping.csv


tmp/oak.db: ../../oba.owl
	cp ../../oba.owl tmp/oba.owl
	semsql make tmp/oba.owl
	#mv ../../oba.db $@

curation/impc-matches.txt:
	runoak annotate --text-file curation/impc-traits-2022-12-01.txt -o curation/impc-matches.txt ../../oba.owl

oak-match: curation/impc-matches.txt


tmp/mirror-%.owl:
	wget $(OBOBASE)/$*.owl -O $@

tmp/oba-merged-%.owl: ../../oba.owl tmp/mirror-%.owl
	$(ROBOT) merge -i $< -i tmp/mirror-$*.owl -o $@

../mappings/oba-%-phenotype.sssom.tsv:
	sssom parse $< -I json -C sssom_default_only -F OBA:9000001

$(TMPDIR)/mirror-%.owl:
	wget $(OBOBASE)/$*.owl -O $@


$(TMPDIR)/lexmatch-%.sssom.tsv: $(TMPDIR)/%.db
	runoak -i $< lexmatch -o $@

$(TMPDIR)/merge-oba-vt.owl: $(TMPDIR)/mirror-oba.owl $(TMPDIR)/mirror-vt.owl
	$(ROBOT) merge -i $< -i $(TMPDIR)/mirror-vt.owl -o $@
