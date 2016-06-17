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

  for i in SPECS SOURCES BUILDROOT BUILDDIR RPMS SRPMS
  do
     mkdir -p $specFileDir/$i
  done

  cp $specFileName $specFileDir/SPECS
}

# Create the archive to be packaged.
# PARAMS :
# - the spec file name
createArchive()
{
   local specFileName=$1
   local specFileDir=$(getSpecFileDir "$specFileName")

   local tarFileName=$(spectool -S $specFileName|grep "Source0"|sed -e "s/Source0: //")

   [[ -z $tarFileName ]] && exitWithError "No tar file name specified, aborting !", 2

   local specFileDirName=$(getSpecFileDirName $specFileName) 


   tar zcf $specFileDir/SOURCES/$tarFileName $specFileDirName --transform "s|^$specFileDirName/||"
}

# Create the RPM package
# PARAMS : 
# - the spec file name
createRpm()
{
  local specFileName="$1"

  infoLog "Creating package(s) for SPEC file $specFileName"

  createTargetDirectoryLayout $specFileName
  createArchive $specFileName

  local specFileDir=$(getSpecFileDir $specFileName)
 
  rpmbuild --define "_topdir $specFileDir" -ba $specFileDir/SPECS/$(basename $specFileName)  

  local resultDir=$(pwd)/target/results
  mkdir -p $resultDir || true

  for i in $(find $resultDir/RPMS/*.rpm -name "*.rpm")
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
