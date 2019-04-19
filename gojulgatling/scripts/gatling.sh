#!/bin/bash

set -e

export GATLING_HOME=/usr/share/gatling

${GATLING_HOME}/bin/gatling.sh $@
