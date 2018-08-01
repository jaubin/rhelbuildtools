#!/bin/bash

set -e

SCRIPT_NAME=$(basename $0)

usage() 
{
   cat >&2 <<-EOF

   USAGE : $SCRIPT_NAME <spec_file_name>

   Create a RPM from what has been specified in file spec_file_name. File
   spec_file_name must be located in a subdirectory of the current directory.
   The resulting RPM is put under directory $(pwd)/target/results

   This script determines the version of RPM files using a file 
   project-info.properties which must be located under the current directory.
   This file is a standard property file which must at least define an entry
   named "project.version".

   Note that this program does not use mock, so it is NOT intended to be used
   by anything which uses a compiler, as the environment may interfere with
   the build process.

   In some cases the RPM package may depend on a big source archive. If this
   is the case create a script named get_source_archive which is in charge
   of getting this archive and storing it in the directory of the SPEC file.

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

# Return the single directory name of the RPM spec file to
# process.
# PARAMS :
# - the spec file name
# RETURNS :
# - the single directory name of the RPM spec file to process.
getSpecFileDirName()
{
   local specFilePath=$1

   local res="$(basename $(dirname $specFilePath))"
   [[ -z $res ]] && exitWithError "No path found for SPEC FILE $specFilePath" 1

   echo $res
}

# Return the working directory of the RPM spec file to process.
# PARAMS :
# - the spec file name
# RETURNS :
# - the working directory of the RPM spec file to process
getSpecFileDir()
{
   local specFilePath=$1

   local suffix="$(getSpecFileDirName $specFilePath)"
   [ "$suffix" = . ] && suffix="" || suffix="/$suffix"
   echo "$(pwd)/target${suffix}"
}

# Create the target directory layout for the RPM spec file to process.
# PARAMS :
# - the spec file name
createTargetDirectoryLayout()
{
  local specFileName=$1
  local specFileDir=$(getSpecFileDir "$specFileName")

  rm -rf $specFileDir
  mkdir -p $specFileDir

  for i in SPECS SOURCES BUILDROOT BUILD RPMS SRPMS
  do
     mkdir -p $specFileDir/$i
  done

  cp $specFileName $specFileDir/SPECS
}

# Return the project version.
# RETURNS
# - the project version
getProjectVersion()
{
   local projTies="project-info.properties"
   [ -f $projTies ] || projTies="../project-info.properties"
   [ -f $projTies ] || exitWithError "No project-info.properties found ! Aborting !" 5

   local res=$(grep "project.version=" $projTies | cut -d\= -f2)

   [[ -z "$res" ]] && exitWithError "No project.version in project-info.properties found, aborting !" 3

   echo $res
}

# Download the source package if necessary.
# This step can be mandatory if the source package
# is huge and cannot be put on the SCM.
# PARAMS 
# - the spec file name.
getSourcePackageIfNecessary()
{
   local specFileName=$1
   local specFileDir=$(getSpecFileDirName "$specFileName")
   local downloadScript="${specFileDir}/get_source_archive"

   if [ -f "$downloadScript" ]
   then
       sh "$downloadScript"	   
   fi	   
}

# Create the archive to be packaged.
# PARAMS :
# - the spec file name
createArchive()
{
   local specFileName=$1
   local specFileDir=$(getSpecFileDir "$specFileName")

   getSourcePackageIfNecessary "$specFileName"

   # spectool needs a project_version property set in order to work
   # here we put a dummy value to make it happy...
   local tarFileName=$(PROJECT_VERSION=dummy spectool -S $specFileName|grep "Source0"|sed -e "s/Source0: //")

   [[ -z "$tarFileName" ]] && exitWithError "No tar file name specified, aborting !" 2

   local specFileDirName=$(getSpecFileDirName $specFileName) 


   tar zcf $specFileDir/SOURCES/$tarFileName $specFileDirName --exclude=target --transform "s|^$specFileDirName/||"
}

# Create the RPM package
# PARAMS : 
# - the spec file name
createRpm()
{
  local specFileName="$1"

  local projectVersion=$(getProjectVersion)

  infoLog "Creating package(s) for SPEC file $specFileName with version $projectVersion"

  createTargetDirectoryLayout $specFileName
  createArchive $specFileName

  local specFileDir=$(getSpecFileDir $specFileName)
 
  PROJECT_VERSION=$projectVersion rpmbuild --define "_topdir $specFileDir" --define "debug_package %{nil}" -ba $specFileDir/SPECS/$(basename $specFileName)  

  local resultDir=$(pwd)/target/results
  mkdir -p $resultDir || true

  for i in $(find $specFileDir/RPMS -name "*.rpm")
  do
     cp $i $resultDir
  done

  infoLog "Package(s) created and available under directory $resultDir" 
}

if [ $# -ne 1 ]
then
   usage
   exit 10
elif [ $1 == '-h' ]
then
   usage
   exit 0
else
   createRpm $1
fi  
