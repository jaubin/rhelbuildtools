#!/bin/bash

SCRIPT_NAME=$(basename $0)
WAR_RPM_TEMPLATES="/usr/share/gojulrpmbuildtools/war"
rpmResultDir=$(pwd)/target/rpmResults

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
  mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec | sed -e "s/-/_/g"
}

# Return the RPM spec file name with
# its path corresponding to the WAR file
# warFile
# PARAMS :
# - warFile : the war file.
getSpecFileName()
{
  local warFileName="$@"
  local warName=$(getWarName $warFileName)
  echo "$(getRpmWorkDir)/SPECS/${warName}.spec"
}

# Prepare the RPM spec file which corresponds
# to the WAR file passed as a parameter.
# PARAMS :
# - warFileName : the WAR file name.
prepareSpecFile()
{
  local warFileName="$@"
  local warName=$(getWarName $warFileName)
  local targetSpecFile=$(getSpecFileName "$warFileName")

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

# Copy the default logback.xml
# if necessary, i.e. if the app
# does not already defines another one.
# PARAMS :
# - the WAR file name
copyLogConfigIfNecessary()
{
   local warFile="$1"
   local configAppsDir=$(getConfigAppsDir "$warFile")
   local targetLogConfig="${configAppsDir}/logback.xml"

   if [ ! -f $targetLogConfig ]
   then
      local warName=$(getWarName "$warFile")
      cp $WAR_RPM_TEMPLATES/logback_template.xml $targetLogConfig
      sed -i "s/@@WARNAME@@/$warName/g" $targetLogConfig
   fi
}

# Prepare the configApps directory for WAR file
# warFile
# PARAMS :
# - the WAR file name
prepareConfigApps()
{
   local warFile="$1"
   local warName="$(getWarName $warFile)"
 
   local sourceConfigAppsDir="$(dirname $warFile)/../src/main/configApps/$warName"
   local globalTargetConfigAppsDir="$(getRpmWorkSourceDir)/configApps"

   mkdir -p $globalTargetConfigAppsDir
 
   if [ -d "$sourceConfigAppsDir" ]
   then
      cp -r $sourceConfigAppsDir $globalTargetConfigAppsDir
   else
      mkdir -p $globalTargetConfigAppsDir/$warName
   fi

   copyLogConfigIfNecessary "$warFile"
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

# Prepare the tgz archive which will be the source.
# PARAMS : 
# - the war file name
prepareArchive()
{
   local warFile="$1"
   local warName=$(getWarName "$warFile")

   local curDir=$(pwd)
   cd $(getRpmWorkSourceDir)

   tar zcf ${warName}.tgz configApps ${warName}.xml ${warName}.war
   rm -rf configApps ${warName}.xml ${warName}.war

   cd $curDir
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

   prepareArchive "$warFileName"
}

# Create a RPM for the WAR file passed as a parameter.
# PARAMS :
# - warFile the WAR file for which a RPM must be created
createRpmForWar()
{
   local warFileName="$1"
   local workDir=$(getRpmWorkDir)

   infoLog "Creating RPM package for file $warFileName"

   createDirectoriesAndRpmBuildFiles "$warFileName"
   rpmbuild --define "_topdir $workDir" --define "debug_package %{nil}" -ba $(getSpecFileName $warFileName)

   mkdir -p $rpmResultDir || true

   for i in $(find $workDir/RPMS -name "*.rpm")
   do 
      cp $i $rpmResultDir
   done

   infoLog "RPM package create for file $warFileName and available under $rpmResultDir"
}

if [ "$1" == "-h" ]
then
   usage
   exit 0
elif [ $# -ne 0 ]
then
   infoLog "This script does not take any parameter !"
   usage
   exit 1
fi

rm -rf $(getRpmWorkDir) $rpmResultDir

for i in $(findWars)
do
   createRpmForWar $i
done
