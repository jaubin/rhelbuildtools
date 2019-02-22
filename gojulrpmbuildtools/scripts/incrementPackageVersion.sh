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

   Note that it does nothing if the version string contains a dash,
   as those version strings are often related to unstable versions
   according to SEMVER standards.

EOF
}

performIncrement()
{
   [ -f project-info.properties ] || exitWithError "No project-info.properties in this directory !" 1

   local projectVersion=$(grep "^project.version=" project-info.properties)
   
   if [[ "$projectVersion" == *"-"* ]]
   then
      echo >&2 "Found an unstable version according to SEMVER spec - not performing any incrementation"
      exit 0
   fi

   local projectVersionPrefix=${projectVersion%.[0-9]*}
   local projectVersionSuffix=${projectVersion##*.}

   ((projectVersionSuffix++))

   sed -i "s/^project.version=.*/${projectVersionPrefix}.${projectVersionSuffix}/" project-info.properties
}

performIncrement
