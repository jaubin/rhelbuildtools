#!/bin/bash

SCRIPT_NAME=$(basename $0)

exitWithError()
{
   echo >&2 "$1"
   exit $2
}

usage()
{
   cat >&2 <<-EOF

   USAGE $SCRIPT_NAME

   This script will look into the project-info.properties
   in the current directory and increment the project.version entry
   by one on its last digit.

EOF
}

performIncrement()
{
   [ -f project-info.properties ] || exitWithError "No project-info.properties in this directory !" 1

   local projectVersion=$(grep "^project.version=" project-info.properties)
   
   local projectVersionPrefix=${projectVersion%.[0-9]*}
   local projectVersionSuffix=${projectVersion##*.}

   ((projectVersionSuffix++))

   sed -i "s/^project.version=.*/${projectVersionPrefix}.${projectVersionSuffix}/" project-info.properties
}

performIncrement
