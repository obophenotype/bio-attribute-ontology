OBO=http://purl.obolibrary.org/obo
USECAT= --catalog-xml catalog-v001.xml

all: oba.owl

oba.owl: oba-edit.obo
	ontology-release-runner --ignore-selected-equivalent-pairs 'CL:0000000' --ignoreLock --skip-release-folder --skip-format owx --no-subsets --outdir . --allow-overwrite --asserted --simple --reasoner elk oba-edit.obo


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
