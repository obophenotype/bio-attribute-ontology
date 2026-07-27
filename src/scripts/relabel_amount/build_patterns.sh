#!/bin/sh
# Regenerate the DOSDP pattern OWL files for label analysis.
#
# This mirrors what `src/ontology/run.sh` does, minus the `-ti` flags it
# hardcodes (there is no TTY here). The image is deliberately one that is
# already on disk rather than the v1.6 pinned in run.sh.conf: this build exists
# only to read labels back out, never to produce a committed artifact. CI
# (.github/workflows/dosdp.yml) regenerates definitions.owl with v1.6 and
# auto-commits it.
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

ODK_IMAGE=${ODK_IMAGE:-obolibrary/odkfull:latest}
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
