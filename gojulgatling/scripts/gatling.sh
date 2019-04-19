#!/bin/bash

set -e

export GATLING_HOME=/usr/share/gatling

RESULTS_DIR="${HOME}/gatling/results"
[ -d "$RESULTS_DIR" ] || mkdir -p "$RESULTS_DIR"

${GATLING_HOME}/bin/gatling.sh -rf ${RESULTS_DIR} $@
