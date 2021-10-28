## Customize Makefile settings for oba
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile



USECAT= --catalog-xml catalog-v001.xml
OWLTOOLS=OWLTOOLS_MEMORY=12G owltools $(USECAT)
MODS = entity_attribute entity_attribute_location attribute_location

all: oba.owl oba.obo all_subsets
all_subsets: subsets/oba-basic.obo
release: all copy-release

TARGETS = oba.obo oba.owl imports subsets


copy-release:
	cp -pr $(TARGETS) ../.. && cd ../.. && git add imports/*

# CORE is the edited source plus compiled modules
oba-core.owl: oba-edit.obo $(OTHER_SRC)
	$(OWLTOOLS) $^ --merge-support-ontologies -o -f ofn $@
oba-core.obo: oba-core.owl
	$(OWLTOOLS) $< -o -f obo --no-check $@.tmp && grep -v ^owl-axioms $@.tmp > $@

test: oba-core.owl
	$(ROBOT) reason -i $< 


# perform materialization.
# Note we use robot materialize plus a subset of properties, see https://github.com/obophenotype/bio-attribute-ontology/issues/8
oba-materialized.owl: oba-core.owl all_imports basic_properties.txt
	ROBOT_JAVA_ARGS=$(ROBOT_JAVA_ARGS) $(ROBOT) materialize -T basic_properties.txt -i $<  -o $@.tmp.owl && mv $@.tmp.owl $@
.PRECIOUS: oba-materialized.owl

REFL_ONT = $(URIBASE)/oba/imports/reasoner_axioms.owl
oba-materialized-spiked.owl: oba-materialized.owl 
	$(OWLTOOLS) $< --add-imports-declarations $(REFL_ONT) -o $@

# Materialization generates redundant links - perform reduction
# TODO: GO/CL
ALLOW_EQUIVS=true
oba-reduced.owl: oba-materialized-spiked.owl
	ROBOT_JAVA_ARGS=$(ROBOT_JAVA_ARGS) $(ROBOT) reason -r elk -e $(ALLOW_EQUIVS) -i $< relax reduce  -o $@.tmp.owl && mv $@.tmp.owl $@
.PRECIOUS: oba-materialized.owl

subsets/oba-basic.owl: oba.owl
	$(OWLTOOLS) $< --remove-imports-declarations --make-subset-by-properties -f BFO:0000050 --remove-dangling --remove-axioms -t EquivalentClasses --set-ontology-id $(URIBASE)/oba/$@ -o $@
subsets/oba-basic.obo: subsets/oba-basic.owl
	$(OWLTOOLS) $< -o -f obo --no-check $@.tmp && grep -v ^owl-axioms $@.tmp > $@

# TODO: fold into previous set
oba.owl: oba-reduced.owl
	$(OWLTOOLS) $< --remove-import-declaration $(REFL_ONT) --set-ontology-id $(URIBASE)/$@ -o $@

oba.obo: oba.owl
	$(OWLTOOLS) $< -o -f obo --no-check $@.tmp && grep -v ^owl-axioms $@.tmp > $@

oort: oba-core.owl
	ontology-release-runner $(USECAT) --ignore-selected-equivalent-pairs 'CL:0000000'  --ignoreLock --skip-release-folder --skip-format owx --skip-format obo --no-subsets --outdir target --allow-overwrite --asserted --simple --reasoner elk $<


# ----------------------------------------
# VT
# ----------------------------------------

# TODO: this is actually fetched from BioPortal
vt.obo:
	wget $(URIBASE)/vt.obo -O $@


# ----------------------------------------
# Regenerate imports
# ----------------------------------------
# Uses OWLAPI Module Extraction code

# Type 'make imports/X_import.owl' whenever you wish to refresh the import for an ontology X. This is when:
#
#  1. X has changed and we want to include these changes
#  2. We have added onr or more new IRI from X into oba-edit.owl
#  3. We have removed references to one or more IRIs in X from oba-edit.owl
#
# You should NOT edit these files directly, changes will be overwritten.
#
# If you want to add something to these, edit oba-edit.owl and add an axiom with a IRI from X. You don't need to add any information about X.

# Ontology dependencies
# We don't include clo, as this is currently not working
#IMPORTS = pato uberon chebi po go cl so pr

# Make this target to regenerate ALL
#all_imports_owl: $(patsubst %, imports/%_import.owl,$(IMPORTS))
#	touch $@
#all_imports_obo: $(patsubst %, imports/%_import.obo,$(IMPORTS))
#	touch $@
#all_imports: all_imports_owl all_imports_obo
#	touch $@


# File used to seed module extraction
#imports/seed.tsv: oba-core.owl
#	if [ $(IMP) = true ]; then owltools $(USECAT) $< --merge-support-ontologies --export-table $@.tmp && cut -f1 $@.tmp > $@; fi

#imports/%_import.owl: $(SRC) mirror/%.owl imports/seed.tsv
#	if [ $(IMP) = true ]; then robot extract -i mirror/$*.owl -T imports/seed.tsv -m BOT -O $(URIBASE)/oba/$@ -o $@; fi

#imports/%_import.obo: imports/%_import.owl
#	if [ $(IMP) = true ]; then owltools $(USECAT) $< -o -f obo $@; fi


KEEPRELS = BFO:0000050 BFO:0000051 RO:0002202 immediate_transformation_of

# clone remote ontology locally, perfoming some excision of relations and annotations

mirror/%.obo:
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then wget --no-check-certificate $(URIBASE)/$*.obo -O $@ && touch $@; fi
.PRECIOUS: mirror/%.obo

mirror/%.owl: mirror/%.obo
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(OWLTOOLS) $< --remove-annotation-assertions -r -l --remove-dangling-annotations --make-subset-by-properties -f $(KEEPRELS)  -o $@; fi
.PRECIOUS: mirror/%.owl

mirror/go.owl: mirror/go.obo
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(OWLTOOLS) $< --remove-annotation-assertions -r -l --remove-dangling-annotations --remove-disjoints --make-subset-by-properties -f $(KEEPRELS)  -o $@; fi

mirror/ro.owl:
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(OWLTOOLS) $(URIBASE)/ro.owl --merge-imports-closure -o $@; fi
.PRECIOUS: mirror/%.owl

mirror/uberon.owl:
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(OWLTOOLS) $(URIBASE)/uberon/basic.owl --remove-annotation-assertions -r -l -s -d --remove-axiom-annotations --remove-dangling-annotations --make-subset-by-properties -f $(KEEPRELS) --set-ontology-id $(URIBASE)/uberon.owl -o $@; fi
.PRECIOUS: mirror/%.owl

mirror/po.owl:
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(OWLTOOLS) $(URIBASE)/po.owl --remove-annotation-assertions -r -l -s -d --remove-axiom-annotations --remove-dangling-annotations --make-subset-by-properties -f $(KEEPRELS) --set-ontology-id $(URIBASE)/po.owl -o $@; fi
.PRECIOUS: mirror/%.owl

ncbitaxon.obo:
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then wget -N $(URIBASE)/ncbitaxon/subsets/taxslim.owl; fi
.PRECIOUS: ncbitaxon.obo

mirror/ncbitaxon.owl: ncbitaxon.obo
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(OWLTOOLS) $< --remove-annotation-assertions -r -l -s -d --remove-axiom-annotations --remove-dangling-annotations  --set-ontology-id $(URIBASE)/ncbitaxon.owl -o $@; fi
.PRECIOUS: mirror/ncbitaxon.owl

mirror/pco.owl: imports/pco_basic.obo
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(OWLTOOLS) $< --set-ontology-id $(URIBASE)/pco.owl -o $@; fi
.PRECIOUS: mirror/pco.owl

# ----------------------------------------
# DESIGN PATTERNS AND TEMPLATES
# ----------------------------------------


#all_modules: all_modules_owl all_modules_obo modules/has_part.owl
#all_modules_owl: $(patsubst %, modules/%.owl, $(MODS))
#all_modules_obo: $(patsubst %, modules/%.obo, $(MODS))

#modules/%-main.owl: modules/%.csv patterns/%.yaml
#	apply-pattern.py -P curie_map.yaml -b http://purl.obolibrary.org/obo/ -i $< -p patterns/$*.yaml -G modules/$*-gci.owl > $@.tmp && mv $@.tmp $@
#modules/%.owl: modules/%-main.owl modules/%-gci.owl
#	owltools $^ --merge-support-ontologies --set-ontology-id $(URIBASE)/oba/$@ -o -f ofn $@

#modules/%.obo: modules/%.owl
#	owltools $< -o -f obo $@.tmp && grep -v ^owl-axioms $@.tmp > $@

# VT is isolated to prevent isa-poisoning
modules/has_part.csv:  $(patsubst %, modules/%.csv, $(MODS))
	./util/make-vt-equiv-tsv.pl $^ > $@

# uses expression-materializing reasoner to infer superclasses and super parent expressions;
modules/existential-graph.owl: oba-core.owl
	$(OWLTOOLS) $< --merge-support-ontologies --reasoner elk --silence-elk --materialize-gcis --reasoner mexr --remove-redundant-inferred-svfs --reasoner elk --remove-redundant-svfs  --set-ontology-id $(URIBASE)/oba/$@ -o $@

# ----------------------------------------
# QC REPORTS
# ----------------------------------------

oba-edit.csv: oba-edit.obo
	$(OWLTOOLS) $< --merge-support-ontologies --export-table $@.tmp && cut -f1 $@.tmp  > $@

# Commenting out the following as there are quite a few missing files, and we now use TSV, not CSV
# @matentzn @cmungall
#ALL_MODS_CSV = $(patsubst %,modules/%.csv,$(MODS))
#
#fill: oba-edit.csv
#	fill-col1-ids.pl $(ALL_MODS_CSV)
#
#labelfill:
#	fill-missing-labels.py -r $(ALL_MODS_CSV)

# ----------------------------------------
# SPARQL REPORTS
# ----------------------------------------

reports/oba-%.csv: oba.owl ../sparql/%.sparql
	arq --data $< --query ../sparql/$*.sparql --results csv > $@.tmp && ./util/curiefy-purls.pl $@.tmp > $@ && rm $@.tmp

