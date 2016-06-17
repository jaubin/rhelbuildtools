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

   echo "$(pwd)/target/$(getSpecFileDirName $specFilePath)"
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
   [ -f project-info.properties ] || exitWithError "No project-info.properties found ! Aborting !" 5

   local res=$(grep "project.version=" project-info.properties | cut -d\= -f2)

   [[ -z "$res" ]] && exitWithError "No project.version in project-info.properties found, aborting !" 3

   echo $res
}


# Create the archive to be packaged.
# PARAMS :
# - the spec file name
createArchive()
{
   local specFileName=$1
   local specFileDir=$(getSpecFileDir "$specFileName")

   # spectool needs a project_version property set in order to work
   # here we put a dummy value to make it happy...
   local tarFileName=$(PROJECT_VERSION=dummy spectool -S $specFileName|grep "Source0"|sed -e "s/Source0: //")

   [[ -z "$tarFileName" ]] && exitWithError "No tar file name specified, aborting !" 2

   local specFileDirName=$(getSpecFileDirName $specFileName) 


   tar zcf $specFileDir/SOURCES/$tarFileName $specFileDirName --transform "s|^$specFileDirName/||"
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
