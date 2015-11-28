OBO=http://purl.obolibrary.org/obo
USECAT= --catalog-xml catalog-v001.xml
SRC=oba-edit.obo

all: oba.owl all_subsets

test: all

release: all copy-release

TARGETS = oba.obo oba.owl imports subsets

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
# VT
# ----------------------------------------
vt.obo:
	wget $(OBO)/vt.obo -O $@

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
# TO
# ----------------------------------------
oba-to.obo: oba-edit.obo
	obo-grep.pl -r 'id: TO' $< > $@

oba-to-xp.obo: oba-to.obo
	obo-grep.pl -r intersection_of $< | obo-filter-tags.pl -t id -t name -t intersection_of > $@
oba-to-noxp.obo: oba-to.obo
	obo-grep.pl --neg -r intersection_of $< | obo-grep.pl --neg -r is_obsolete -  > $@

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
	owltools  $(USECAT) --map-ontology-iri $(OBA_IMPORTS_BASE_URI)/imports/$*_import.owl mirror/$*.owl $< imports/$*_seed.owl --merge-support-ontologies  --extract-module -s $(OBO)/$*.owl -c --remove-axiom-annotations --make-subset-by-properties -f $(KEEPRELS)  --extract-mingraph --set-ontology-id $(OBA_IMPORTS_BASE_URI)/$@ -o $@

imports/%_import.obo: imports/%_import.owl
	owltools $(USECAT) $< -o -f obo $@

# clone remote ontology locally, perfoming some excision of relations and annotations
mirror/%.owl: $(SRC)
	owltools $(OBO)/$*.owl --remove-annotation-assertions -r -l --remove-dangling-annotations --make-subset-by-properties -f $(KEEPRELS)  -o $@
.PRECIOUS: mirror/%.owl
mirror/ro.owl: $(SRC)
	owltools $(OBO)/ro.owl --merge-imports-closure -o $@
.PRECIOUS: mirror/%.owl
mirror/uberon.owl: $(SRC)
	owltools $(OBO)/uberon/basic.owl --remove-annotation-assertions -r -l -s -d --remove-axiom-annotations --remove-dangling-annotations --make-subset-by-properties -f $(KEEPRELS) --set-ontology-id $(OBO)/uberon.owl -o $@
.PRECIOUS: mirror/%.owl
mirror/po.owl: $(SRC)
	owltools $(OBO)/po.owl --remove-annotation-assertions -r -l -s -d --remove-axiom-annotations --remove-dangling-annotations --make-subset-by-properties -f $(KEEPRELS) --set-ontology-id $(OBO)/po.owl -o $@
.PRECIOUS: mirror/%.owl
ncbitaxon.obo:
	wget -N $(OBO)/ncbitaxon.obo
.PRECIOUS: ncbitaxon.obo
mirror/ncbitaxon.owl: ncbitaxon.obo
	OWLTOOLS_MEMORY=12G owltools $< --remove-annotation-assertions -r -l -s -d --remove-axiom-annotations --remove-dangling-annotations  --set-ontology-id $(OBO)/ncbitaxon.owl -o $@
.PRECIOUS: mirror/ncbitaxon.owl

mirror/pco.owl: imports/pco_basic.obo
	OWLTOOLS_MEMORY=12G owltools $< --set-ontology-id $(OBO)/pco.owl -o $@


# ----------------------------------------
# DESIGN PATTERNS AND TEMPLATES
# ----------------------------------------
MODS = entity_attribute entity_attribute_location has_part

all_modules: $(patsubst %, modules/%.owl, $(MODS))

modules/%-main.owl: modules/%.tsv patterns/%.yaml
	apply-pattern.py -b http://purl.obolibrary.org/obo/ -i $< -p patterns/$*.yaml -G modules/$*-gci.owl > $@.tmp && mv $@.tmp $@
modules/%.owl: modules/%-main.owl modules/%-gci.owl
	owltools $^ --merge-support-ontologies -o -f ofn $@

modules/%.obo: modules/%.owl
	owltools $< -o -f obo $@.tmp && grep -v ^owl-axioms $@.tmp > $@

# VT is isolated to prevent isa-poisoning
modules/has_part.tsv: modules/entity_attribute.tsv
	./util/make-vt-equiv-tsv.pl $< > $@


oba-merged.owl: oba-edit.obo modules/entity_attribute.owl
	owltools --use-catalog $^ --merge-support-ontologies -o $@

svfs.owl:
	owltools modules/entity_attribute.owl imports/*owl --merge-support-ontologies --reasoner elk --silence-elk --materialize-gcis -o $@

# ----------------------------------------
# REPORTS
# ----------------------------------------
# See: https://github.com/Planteome/plant-trait-ontology/issues/302

reports/vt-viol.tsv: oba-edit.obo
	blip-findall  -i $< -r uberons "subclass(X,Y),P=attribute_of,differentium(X,P,XQ),id_idspace(XQ,'UBERON'),differentium(Y,P,YQ),id_idspace(YQ,'UBERON'),\+parentRT(XQ,YQ)" -select "x(X,Y,XQ,YQ)" -label -no_pred > $@

reports/pato-viol.tsv: oba-edit.obo
	blip-findall  -i $< -r pato "subclass(X,Y),P=affects_quality,differentium(X,P,XQ),differentium(Y,P,YQ),\+subclassRT(XQ,YQ)" -select "x(X,Y,XQ,YQ)" -label -no_pred > $@

reports/po-viol.tsv: oba-edit.obo
	blip-findall  -i $< -r PO "subclass(X,Y),P=attribute_of,differentium(X,P,XQ),id_idspace(XQ,'PO'),differentium(Y,P,YQ),id_idspace(YQ,'PO'),\+parentRT(XQ,YQ)" -select "x(X,Y,XQ,YQ)" -label -no_pred > $@

reports/po-sc-viol.tsv: oba-edit.obo
	blip-findall  -i $< -r PO "subclass(X,Y),P=attribute_of,differentium(X,P,XQ),id_idspace(XQ,'PO'),differentium(Y,P,YQ),id_idspace(YQ,'PO'),\+subclassRT(XQ,YQ)" -select "x(X,Y,XQ,YQ)" -label -no_pred > $@

reports/eq.tsv: oba-edit.obo
	blip-findall -r go  -r pato -r uberonp -r pato -r CL -i $< -consult util/patterns.pro eq/3 -no_pred -label -use_tabs > $@
reports/eq_root.tsv: oba-edit.obo
	blip-findall -r go  -r pato -r uberonp -r pato -r CL -i $< -consult util/patterns.pro eq_root/3 -no_pred -label -use_tabs > $@.tmp && ./util/fix-ids.pl $@.tmp > $@
reports/eq_eroot.tsv: oba-edit.obo
	blip-findall -r go  -r pato -r uberonp -r pato -r CL -i $< -consult util/patterns.pro eq_eroot/3 -no_pred -label -use_tabs > $@.tmp && ./util/fix-ids.pl $@.tmp > $@
reports/eqw.tsv: oba-edit.obo
	blip-findall -r chebi -r go  -r pato -r uberonp -r pato -r CL -i $< -consult util/patterns.pro eqw/4 -no_pred -label -use_tabs > $@.tmp && ./util/fix-ids.pl $@.tmp > $@

reports/patterns.tsv: oba-edit.obo
	blip-findall -i $< -consult util/patterns.pro idspace_pattern/3 -no_pred > $@
