#!/bin/bash

SCRIPT_NAME=$(basename $0)

set -e

usage()
{
   cat >&2 <<-EOF

   $SCRIPT_NAME <RPM_package>

   Push the RPM package <RPM_package> to the local Maven
   repo. The URL of the Maven Repo must be filled in file
   /etc/gojulrpmbuildtools/maven_repo.properties, property name
   being MAVEN_REPO

   In order to get the stuff working, the RPM package to upload
   must have a Maven-compliant group name.

   An additional requirement is that the Maven repo can be used as
   a RPM repo. This is notably the case for Nexus.

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

# Return the group name of the RPM package file
# passed as a parameter.
# PARAMS
# - the rpm package file name
# RETURNS
# - the group name of the RPM package
getRpmGroup()
{
   rpm -qp --qf "%{GROUP}\n" $1
}

# Return the name of the RPM package file
# passed as a parameter.
# PARAMS
# - the rpm package file name
# RETURNS
# - the name of the RPM package
getRpmName()
{
   rpm -qp --qf "%{NAME}\n" $1
}

# Return the version of the RPM package file
# passed as a parameter.
# PARAMS
# - the rpm package file name
# RETURNS
# - the version of the RPM package
getRpmVersion()
{
   rpm -qp --qf "%{VERSION}\n" $1
}

# Return the URL of the Maven repository used.
# RETURNS
# - the URL of the Maven repository used.
getMavenRepoUrl()
{
   local mavenRepoUrl=$(grep "^MAVEN_REPO=" /etc/gojulrpmbuildtools/maven_repo.properties)

   [[ -z "$mavenRepoUrl" ]] && exitWithError "Parameter MAVEN_REPO not configured !" 1

   mavenRepoUrl=${mavenRepoUrl#MAVEN_REPO=}

   echo $mavenRepoUrl
}

if [ $# -ne 1 ]
then
  infoLog "Bad argument count"
  usage
  exit 1
elif [ "$1" == "-h" ]
then
  usage
  exit 0 
fi  

rpmPackage="$1"

mavenRepoUrl=$(getMavenRepoUrl)
rpmGroupId=$(getRpmGroup "$rpmPackage")
rpmName=$(getRpmName "$rpmPackage")
rpmVersion=$(getRpmVersion "$rpmPackage")

infoLog "Publishing package file $rpmPackage to Maven repo $mavenRepoUrl"

mvn -q deploy:deploy-file \
    "-DgroupId=$rpmGroupId" \
    "-DartifactId=$rpmName" \
    "-Dversion=$rpmVersion" \
    -Dpackaging=rpm \
    -Dfile=$rpmPackage \
    "-Durl=$mavenRepoUrl"

