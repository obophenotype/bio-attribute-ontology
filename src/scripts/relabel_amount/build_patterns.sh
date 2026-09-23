#!/bin/sh
# Regenerate the DOSDP pattern OWL files for label analysis.
#
# This mirrors what `src/ontology/run.sh` does, minus the `-ti` flags it
# hardcodes (there is no TTY here). It defaults to the ODK image pinned in
# src/ontology/run.sh.conf, which CI (.github/workflows/dosdp.yml) also uses and
# which reproduces the committed definitions.owl byte-for-byte; set ODK_IMAGE to
# override it.
#
# IMP=false MIR=false keeps make from touching imports or mirrors; the only
# targets rebuilt are tmp/oba-preprocess.owl and the per-pattern .ofn files.
#
# Usage:
#     build_patterns.sh <repo_root> [make-target...]

set -e

REPO_ROOT=$(cd "$1" && pwd)
shift
TARGETS=${*:-../patterns/definitions.owl}

ODK_TAG=$(sed -n 's/^ODK_TAG=//p' "$REPO_ROOT/src/ontology/run.sh.conf")
ODK_IMAGE=${ODK_IMAGE:-obolibrary/odkfull:${ODK_TAG:-v1.6}}
JAVA_OPTS=${JAVA_OPTS:--Xmx14G}

echo "### image:   $ODK_IMAGE"
echo "### targets: $TARGETS"

docker run --rm \
    -v "$REPO_ROOT":/work \
    -w /work/src/ontology \
    -e ROBOT_JAVA_ARGS="$JAVA_OPTS" \
    -e JAVA_OPTS="$JAVA_OPTS" \
    -e ODK_USER_ID="$(id -u)" \
    -e ODK_GROUP_ID="$(id -g)" \
    "$ODK_IMAGE" \
    make IMP=false MIR=false PAT=true $TARGETS
