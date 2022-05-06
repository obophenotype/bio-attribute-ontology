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

#########################################
### Generating all ROBOT templates ######
#########################################

TEMPLATESDIR=../templates

TEMPLATES=$(patsubst %.tsv, $(TEMPLATESDIR)/%.owl, $(notdir $(wildcard $(TEMPLATESDIR)/*.tsv)))

$(TEMPLATESDIR)/%.owl: $(TEMPLATESDIR)/%.tsv $(SRC)
	$(ROBOT) merge -i $(SRC) template --template $< --output $@ && \
	$(ROBOT) annotate --input $@ --ontology-iri $(ONTBASE)/components/$*.owl -o $@

$(COMPONENTSDIR)/obsoletes.owl: $(TEMPLATESDIR)/replaced.owl
	$(ROBOT) merge -i $< annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) -o $@

test: pattern_schema_checks

RELEASE_ASSETS_RELEASE_DIR=$(foreach n,$(RELEASE_ASSETS), ../../$(n))

deploy_release:
	@test $(GHVERSION)
	ls -alt $(RELEASE_ASSETS_RELEASE_DIR)
	gh release create $(GHVERSION) --notes "TBD." --title "$(GHVERSION)" --draft $(RELEASE_ASSETS_RELEASE_DIR)  --generate-notes
