OBO=http://purl.obolibrary.org/obo
USECAT= --catalog-xml catalog-v001.xml
SRC=oba-edit.obo

all: oba.owl all_subsets

release: all copy-release

TARGETS = oba.obo oba.owl imports

copy-release:
	cp -pr $(TARGETS) ../.. && cd ../.. && git add imports/*

oba-edit-x.obo: oba-edit.obo
	./util/fix-ext-ids.pl $< > $@
.PRECIOUS: oba-edit-x.obo

oba.owl: oba-edit-x.obo
	ontology-release-runner $(USECAT) --ignore-selected-equivalent-pairs 'CL:0000000'  --ignoreLock --skip-release-folder --skip-format owx --no-subsets --outdir . --allow-overwrite --asserted --simple --reasoner elk $<

oba-simple.obo: oba.owl

all_subsets: subsets/oba-basic.obo

#subsets/oba-basic.obo: oba.obo
#	owltools  $(USECAT) $< --extract-module -d OBA:0000001 --remove-dangling --make-subset-by-properties //  --set-ontology-id $(OBO)/oba/$@ -o -f obo $@

subsets/oba-basic.obo: oba-simple.obo
	owltools $< --set-ontology-id $(OBO)/oba/$@ -o -f obo $@

# ----------------------------------------
# OBA
# ----------------------------------------
# See: http://wiki.geneontology.org/index.php/Extensions/x-attribute
# This may later move to its own repo
#
# remember to cd vt && make vt-plus.obo
oba-plus-vt.obo: oba.obo vt/vt-plus.obo
	obo-subtract.pl $< vt/vt-plus.obo > $@.tmp && obo-simple-merge.pl  vt/vt-plus.obo $@.tmp | grep -v ^subset > $@.tmp2 && mv $@.tmp2 $@
# after: cp to oba.obo

# Add TO (plant trait)
# remember to cd trair && make trait.obo
oba-plus-to.obo: oba.obo
	obo-subtract.pl $< traits/trait.obo > $@.tmp && obo-simple-merge.pl  traits/trait.obo $@.tmp > $@.tmp2 && obo-merge-tags.pl -t intersection_of $@.tmp2 traits/trait_xp.obo | grep -v ^subset > $@
# after: cp to oba.obo


legacy-sync:
	cp $(HOME)/repos/go/ontology/extensions/bio-attributes.obo oba-edit.obo



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

# Base URI for local subset imports
OBA_IMPORTS_BASE_URI = $(OBO)/oba

# Ontology dependencies
# We don't include clo, as this is currently not working
IMPORTS = pato uberon chebi po go cl

# Make this target to regenerate ALL
all_imports: $(patsubst %, imports/%_import.owl,$(IMPORTS)) $(patsubst %, imports/%_import.obo,$(IMPORTS))

KEEPRELS = BFO:0000050 BFO:0000051 RO:0002202 immediate_transformation_of

# Create an import module using the OWLAPI module extraction code via OWLTools.
# We use the standard catalog, but rewrite the import to X to be a local mirror of ALL of X.
# After extraction, we further reduce the ontology by creating a "mingraph" (removes all annotations except label) and by 
imports/%_import.owl: $(SRC) mirror/%.owl imports/%_seed.owl
	owltools  $(USECAT) --map-ontology-iri $(OBA_IMPORTS_BASE_URI)/imports/$*_import.owl mirror/$*.owl $< imports/$*_seed.owl --merge-support-ontologies  --extract-module -s $(OBO)/$*.owl -c --remove-axiom-annotations --make-subset-by-properties $(KEEPRELS)  --extract-mingraph --set-ontology-id $(OBA_IMPORTS_BASE_URI)/$@ -o $@

imports/%_import.obo: imports/%_import.owl
	owltools $(USECAT) $< -o -f obo $@

# clone remote ontology locally, perfoming some excision of relations and annotations
mirror/%.owl: $(SRC)
	owltools $(OBO)/$*.owl --remove-annotation-assertions -l --remove-dangling-annotations --make-subset-by-properties -f $(KEEPRELS)  -o $@
.PRECIOUS: mirror/%.owl
mirror/ro.owl: $(SRC)
	owltools $(OBO)/ro.owl --merge-imports-closure -o $@
.PRECIOUS: mirror/%.owl
mirror/uberon.owl: $(SRC)
	owltools $(OBO)/uberon/basic.owl --remove-annotation-assertions -l -s -d --remove-axiom-annotations --remove-dangling-annotations --make-subset-by-properties -f $(KEEPRELS) --set-ontology-id $(OBO)/uberon.owl -o $@
.PRECIOUS: mirror/%.owl
mirror/po.owl: $(SRC)
	owltools $(OBO)/po.owl --remove-annotation-assertions -l -s -d --remove-axiom-annotations --remove-dangling-annotations --make-subset-by-properties -f $(KEEPRELS) --set-ontology-id $(OBO)/po.owl -o $@
.PRECIOUS: mirror/%.owl
ncbitaxon.obo:
	wget -N $(OBO)/ncbitaxon.obo
.PRECIOUS: ncbitaxon.obo
mirror/ncbitaxon.owl: ncbitaxon.obo
	OWLTOOLS_MEMORY=12G owltools $< --remove-annotation-assertions -l -s -d --remove-axiom-annotations --remove-dangling-annotations  --set-ontology-id $(OBO)/ncbitaxon.owl -o $@
.PRECIOUS: mirror/ncbitaxon.owl

mirror/pco.owl: imports/pco_basic.obo
	OWLTOOLS_MEMORY=12G owltools $< --set-ontology-id $(OBO)/pco.owl -o $@
