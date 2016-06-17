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

infoLog()
{
   echo >&2 "$1"
}

exitWithError()
{
   echo >&2 "$1"
   exit $2
}

# Find all the WAR files under the current directory
# RETURNS
# - the list of WAR files under the current directory
findWars()
{
   find . -name "*.war"
}

# Return the RPM work directory.
# RETURNS
# - the RPM work directory
getRpmWorkDir()
{
   echo "$(pwd)/target/rpmwork"
}

getRpmWorkSourceDir()
{
   echo "$(getRpmWorkDir)/SOURCES"
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

# Return the WAR name without extension of the WAR file
# given as a parameter.
# PARAMS :
# - warFile : the war file path.
# RETURNS :
# - the war name corresponding to warFile
getWarName()
{
  local warFile="$1"
  local res=$(basename $warFile ".war")
  [[ -z "$res" ]] && exitWithError "War file $warFile does not seem to be a valid WAR" 1
  echo $res
}

# Extract the WAR version from the pom.xml
# in the current directory
getWarVersion()
{
  mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec 
}

# Prepare the RPM spec file which corresponds
# to the WAR file passed as a parameter.
# PARAMS :
# - warFileName : the WAR file name.
prepareSpecFile()
{
  local warFileName="$@"
  local warName=$(getWarName $warFileName)
  local targetSpecFile="$(getRpmWorkDir)/SPECS/${warName}.spec"

  cp $WAR_RPM_TEMPLATES/war_spec_file_template.spec $targetSpecFile

  sed -i "s/@@WARNAME@@/$warName/g" $targetSpecFile
  sed -i "s/@@WARVERSION@@/$(getWarVersion)/g" $targetSpecFile
}


# Return the configApps work directory
# PARAMS :
# - the WAR file name
# RETURNS :
# - the configApps source directory
getConfigAppsDir()
{
  local warFile="$1"
  local warName=$(getWarName "$warFile")

  echo "$(getRpmWorkSourceDir)/configApps/$warName"
}

# Prepare the configApps directory for WAR file
# warFile
# PARAMS :
# - the WAR file name
prepareConfigApps()
{
   local warFile="$1"
   local targetConfigAppsDir=$(getConfigAppsDir "$warFile")

   

}

# Copy the context.xml template file to the 
# target sources directory and customize it.
copyContextXml()
{
   local warFileName="$1"
   local warName=$(getWarName "$warFileName")

   local targetFileName="$(getRpmWorkSourceDir)/${warName}.xml"

   cp $WAR_RPM_TEMPLATES/context_template.xml $targetFileName
   sed -i "s/@@WARNAME@@/$warName/g" $targetFileName

}

# Create directory structure and copy files to the RPM directory structure
# PARAMS :
# - warName : the WAR file name with its path
createDirectoriesAndRpmBuildFiles()
{
   local warFileName="$1"

   createTargetDirectoryLayout
   prepareSpecFile "$warFileName"

   cp $warFileName $(getRpmWorkSourceDir)

   prepareConfigApps "$warFileName"
   copyContextXml "$warFileName"
}

rm -rf $(getRpmWorkDir)

for i in $(findWars)
do
   createDirectoriesAndRpmBuildFiles $i
done
