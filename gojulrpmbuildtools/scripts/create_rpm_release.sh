#!/bin/bash

SCRIPT_NAME=$(basename $0)

set -e

usage()
{
   cat >&2 <<-EOF

   $SCRIPT_NAME [prefix]

   This script builds all the RPM packages available under the current
   directory, tags the SCM, and then pushes the published packages to the
   remove Maven repository. At last it increases by one the version specified
   in file package-version.properties of the current directory.

   The group name of the RPM packages to publish must be compliant with 
   Maven specifications. Thus the remove Maven repo, which is specified in
   file /etc/gojulrpmbuildtools/maven_repo.properties, must be able to act
   as an RPM repository.

   The prefix parameter is optional and is used in case you need to publish
   your artifact in a sub-repository of your Maven repo. This is a property
   notably supported by Artifactory.

   In order to be able to use this script on a CI server you must first ensure
   it can authenticate automatically to the VCS server. For example SSH key
   authentication is a good choice.

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

# Return the project version.
# RETURNS
# - the project version
getProjectVersion()
{
   [ -f project-info.properties ] || exitWithError "No project-info.properties found ! Aborting !" 5

   local res=$(grep "project.version=" project-info.properties | cut -d\= -f2)

   [[ -z "$res" ]] && exitWithError "No project.version in project-info.properties found, aborting !" 3

   echo $res
}

if [ "$1" == "-h" ]
then
   usage
   exit 0
elif [ "$#" -gt 1 ]
then
   echo >&2 "Bad argument count"
   usage
   exit 1
fi

projectVersion=$(getProjectVersion)
repoPrefix="$1"

$(dirname $0)/build_packages.sh

git tag -a "$projectVersion" -m "Version $projectVersion"
git push --tags

$(dirname $0)/incrementPackageVersion.sh
git add project-info.properties
git commit -m "Updated project information"
git push

for i in $(find target/results -name "*.rpm")
do
   $(dirname $0)/publish_rpm.sh $i "$repoPrefix"
done
