#!/bin/sh

set -e

SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)

CUR_DIR=$(pwd)

# Print an help message explaining the use of this program.
usage()
{
   cat >&2 <<-EOF

   Usage: $SCRIPT_NAME [-r|-h]

   This program automatically detects your project type and invokes
   the proper builder accordingly.
   As of now supported project types are :
   - RPM projects (i.e. projects with RPM builds)
   - Java Maven projects, with the system attempting to create RPM packages for WAR and Spring Boot apps.

   This script takes the following optional parameters into account :
   * -h : print this help message
   * -r : create a release.

EOF
}

# Print a log message.
# PARAMS :
# - the message to print.
infoLog()
{
   echo >&2 "$1"
}

# Return the RPM repo prefix if it exists,
# otherwise an empty string.
# RETURNS :
# - the RPM repo prefix
getRpmRepoPrefix()
{
   local settingsFile="/etc/gojulrpmbuildtools/maven_repo.properties"

   [ -f "$settingsFile" ] || echo ""

   local mavenRepoPrefix=$(grep "^MAVEN_RPM_REPO_PREFIX=" /etc/gojulrpmbuildtools/maven_repo.properties) 

   [[ -z "$mavenRepoPrefix" ]] && echo "" || echo ${mavenRepoPrefix#MAVEN_RPM_REPO_PREFIX=}
}

# Check if the project is an RPM project,
# false otherwise.
# RETURNS :
# - a non-empty string if the project is an RPM
# project, false otherwise. 
isRpmProject()
{
   cd "$CUR_DIR"
   [ -f "project-info.properties" ] || echo ""

   local specFileCount=$(find . -mindepth 2 -maxdepth 2 -type f -name "*.spec" | wc -l)

   [[ $specFileCount -gt 0 ]] && echo "rpm" || echo ""
}

# Build RPM project for development purposes.
buildRpmForDevelopment()
{
   infoLog "Building RPM project for development purposes"
   cd "$CUR_DIR"

   build_packages.sh
}

# Build RPM project for release
buildRpmForRelease()
{
   infoLog "Building RPM project for release purposes"

   cd "$CUR_DIR"

   local rpmRepoPrefix=$(getRpmRepoPrefix)
   [[ -z "$rpmRepoPrefix" ]] && infoLog "Packages won't be put under a sub-repo of the repo you've set up" || infoLog "Packages will be put under the subrepo $rpmRepoPrefix of the repo you've set up"

   create_rpm_release.sh "$rpmRepoPrefix"
}

# Build the project
# PARAM :
# - the project type.
buildProject()
{
   local projectType="$1"

   if [[ -z "$RELEASE_MODE" ]]
   then
      build${projectType}ForDevelopment
   else
      build${projectType}ForRelease
   fi
}

if [ "$1" == "-h" ]
then
   usage
   exit 0
elif [ "$1" == "-r" ]
then
   RELEASE_MODE=1
elif [ $# -ne 0 ]
then
   infoLog "Bad argument count or invalid argument !"
   usage
   exit 1
fi

if [[ -n "$(isRpmProject)" ]]
then
   buildProject "Rpm"
fi
