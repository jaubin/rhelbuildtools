#!/bin/bash

SCRIPT_NAME=$(basename $0)
WAR_RPM_TEMPLATES="/usr/share/gojulrpmbuildtools/war"

set -e

usage()
{
   cat >&2 <<-EOF
  
      USAGE: $SCRIPT_NAME

      This script must be executed under a directory where a Maven
      pom.xml file is present.

      It looks for any WAR file found under the current directory
      and creates a RPM package for each of them. Each of the generated
      RPM files must be directly under Maven's target/ directory.

      If your WAR has configuration files they must be put under directory
      target/../src/main/configApps/<warname>. The tool will declare them
      as RPM configuration files and package them under directory
      \$CATALINA_BASE/configApps/<warName>

EOF
}

# Find all the WAR files under the current directory
# RETURNS
# - the list of WAR files under the current directory
findWars()
{
   find . -name "*.war"
}

# Return the RPM working directory.
getRpmWorkDir()
{
   echo "$(pwd)/target/rpmwork"
}

# Create the RPM work directory layout.
createTargetDirectoryLayout()
{
  local targetDir=$(getRpmWorkDir)

  rm -rf $targetDir
  mkdir -p $targetDir

  for i in SPECS SOURCES BUILDROOT BUILD RPMS SRPMS
  do
     mkdir -p $targetDir/$i
  done
}

# Copy files to the RPM directory structure
# PARAMS :
# - warName : the WAR file name with its path
copyRpmBuildFiles()
{
   local warFileName="$1"

   createTargetDirectoryLayout
}

