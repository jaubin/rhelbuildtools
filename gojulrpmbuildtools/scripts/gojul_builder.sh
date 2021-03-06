#!/bin/sh

set -e

SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)

CUR_DIR=$(pwd)

# Print an help message explaining the use of this program.
usage()
{
   cat >&2 <<-EOF

   Usage: $SCRIPT_NAME [-r|-h|-s]

   This program automatically detects your project type and invokes
   the proper builder accordingly.
   As of now supported project types are :
   - RPM projects (i.e. projects with RPM builds)
   - Java Maven projects, with the system attempting to create RPM packages for WAR and Spring Boot apps.
   - Custom projects, the ones which have a build.sh script at their root. This one must take the "-r" parameter into account for builds in release mode.

   This script takes the following optional parameters into account :
   * -h : print this help message
   * -r : create a release.
   * -s : launch Sonar on the release. Note that we assume there that you have set up properly Sonar settings. For Maven projects this must be done in the POM file.

   Note that options -r and -s are mutually exclusive.

   If the repo has an ansible subdirectory it will treat this subdirectory
   as a playbook and perform substitutions of string {{lookup('env', 'PROJECT_VERSION')}}
   with -<the_version> when tagging. The process is transparent to you. This way
   you can version your Ansible playbooks alongside your projects themselves.
EOF
}

# Print a log message.
# PARAMS :
# - the message to print.
infoLog()
{
   echo >&2 "$1"
}

# Print an error message and exists.
# PARAMS :
# - the error message.
die()
{
   infoLog "$1"
   exit 255
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

   $SCRIPT_DIR/build_packages.sh
}

# Build RPM project for release
buildRpmForRelease()
{
   infoLog "Building RPM project for release purposes"

   cd "$CUR_DIR"

   local rpmRepoPrefix=$(getRpmRepoPrefix)
   [[ -z "$rpmRepoPrefix" ]] && infoLog "Packages won't be put under a sub-repo of the repo you've set up" || infoLog "Packages will be put under the subrepo $rpmRepoPrefix of the repo you've set up"

   $SCRIPT_DIR/create_rpm_release.sh "$rpmRepoPrefix"
}

# Return true if the project is a Maven project,
# false otherwise.
# RETURNS :
# - a non-empty string if the project is a Maven project, an empty one otherwise.
isMavenProject()
{
   cd "$CUR_DIR"
   [ -f pom.xml ] && echo "Maven" || echo ""
}

# Return true if the specified project is a Maven WAR
# project, false otherwise.
# RETURN :
# - a non-empty string if the specified project is a Maven WAR
# project, an empty string otherwise.
isMavenWarProject()
{
   cd "$CUR_DIR"
   grep "<packaging>war</packaging>" $(find . -name "pom.xml") > /dev/null && echo "Maven WAR" || echo ""
}

# Return true if the specified project is a Maven SpringBoot
# project, false otherwise.
# RETURN :
# - a non-empty string if the specified project is a Maven Spring
# Boot project, an empty string otherwise.
isMavenSpringBootProject()
{
   cd "$CUR_DIR"
   grep "<artifactId>spring-boot-maven-plugin</artifactId>" $(find . -name "pom.xml") > /dev/null && echo "Spring Boot" || echo ""

}

# Build a Maven project for development purposes.
buildMavenForDevelopment()
{
   infoLog "Building Maven project for development purposes"

   cd "$CUR_DIR"
   mvn clean deploy
}

# Publishes the RPM packages found in the current directory,
# which were generated by an automated RPM generation script.
publishGeneratedRpms()
{
   local rpmRepoPrefix=$(getRpmRepoPrefix)

   for i in $(find . -type f -name "*.rpm"|grep "rpmResults")
   do
       $SCRIPT_DIR/publish_rpm.sh "$i" "$rpmRepoPrefix"
   done
}

# Return the version for a Maven project.
# RETURNS :
# - the version for a Maven project.
getMavenProjectName()
{
   cd "$CUR_DIR"

   if [[ -n "$(isMavenSpringBootProject)" ]]
   then
      local pomFile=$(grep -l '<artifactId>spring-boot-maven-plugin</artifactId' $(find . -name "pom.xml") | head -1)
      if [ -n "$pomFile" ]
      then
         mvn -f "$pomFile" -q -Dexec.executable="echo" -Dexec.args='${project.name}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec
      else
         echo ""
      fi
   else
      echo ""
   fi
}

# Return the version for a Maven project.
# RETURNS :
# - the version for a Maven project.
getMavenProjectVersion()
{
   mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec | sed -e "s/-SNAPSHOT//g" | sed -e "s/-/_/g"
}

# Build a Maven project for release purposes.
buildMavenForRelease()
{
   infoLog "Building Maven project for release purposes"

   cd "$CUR_DIR"
   mvn -B clean release:clean release:prepare release:perform -Dtag=$(getMavenProjectVersion)

   cd target/checkout

   if [[ -n "$(isMavenSpringBootProject)" ]]
   then
      infoLog "Found SpringBoot project - building Spring Boot RPMs"
      $SCRIPT_DIR/build_springboot_rpm.sh
   elif [[ -n "$(isMavenWarProject)" ]]
   then
      infoLog "Found WAR project - building WAR RPMs"
      $SCRIPT_DIR/build_war_rpm.sh
   else
      infoLog "No specific WAR or Spring Boot app found"
   fi

   publishGeneratedRpms
}

# If the current repo has an ansible sub-directory
# check the mandatory files are there, otherwise does
# nothing.
checkAnsibleStructureIfApplicable()
{
   if [ -d ansible ]
   then
      [ -f meta/main.yml ] || die "File meta/main.yml at the root of your repo is mandatory if your repo contains a playbook" 
   fi
}

# Return the name for an RPM project
# RETURNS :
# - nothing - this is not supported 
getRpmProjectName()
{
   echo ""
}

# Return the project version for an RPM project.
# RETURNS :
# - the project version for an RPM project
getRpmProjectVersion()
{
   grep "project.version=" project-info.properties | cut -d\= -f2 
}

# Prepare the Ansible module for tagging if applicable.
# PARAMS :
# - the project version
prepareAnsibleForTaggingIfApplicable()
{
   local name="$1"
   local version="$2"
   if [ -n "$name" ]
   then
      $SCRIPT_DIR/gojul_ansible_playbook_generator.sh "$name" "$version"
   fi	   

   if [ -d ansible ]
   then
      local tmpDir=$(mktemp -d)
      cp -r ansible/ $tmpDir
      find ansible -type f -exec sed -i "s/[-]*\\s*{{\\s*lookup\\s*(\\s*'env'\\s*,\\s*'PROJECT_VERSION'\\s*)\\s*}}/-${version}/g" {} \; || true
      git commit -a -m "Updated Ansible playbook package version to ${version}" > /dev/null || true
      echo "$tmpDir"
   else
      echo ""   
   fi
}

revertAnsiblePlaybookPackageVersion()
{
   local originalDir="$1"

   if [ -n "$originalDir" ]
   then
      rm -rf ansible
      cp -r "${originalDir}/ansible" .
      rm -rf "$originalDir"
      if [ -f ansible/.playbook_gojul_generated ]
      then
         git rm -r ansible meta
      fi	      
      if git commit -a -m "Restored original playbook"
      then
         git push
      else
         infoLog "Nothing to commit"
      fi
   fi
}

# Run Sonar on a Maven project.
runSonarForMaven()
{
   mvn clean verify package sonar:sonar
}

# Run Sonar on a RPM project
runSonarForRpm()
{
   infoLog "Unsupported project type for Sonar Analysis : RPM"
}

# Build the project
# PARAM :
# - the project type.
buildProject()
{
   local projectType="$1"

   if [[ -n "$SONAR_MODE" ]]
   then
      runSonarFor${projectType}
   elif [[ -z "$RELEASE_MODE" ]]
   then
      build${projectType}ForDevelopment
   else
      checkAnsibleStructureIfApplicable
      local tmpDir=$(prepareAnsibleForTaggingIfApplicable $(get${projectType}ProjectName) $(get${projectType}ProjectVersion))
      build${projectType}ForRelease || {
         revertAnsiblePlaybookPackageVersion "$tmpDir"
         die "Build failed"
      }
      revertAnsiblePlaybookPackageVersion "$tmpDir"
   fi
}

# Return true if we're in a custom build, false otherwise.
# RETURNS:
# - true if we're in a custom build, false otherwise.
isCustomProject()
{
   cd "$CUR_DIR"
   [ -f build.sh ] && echo "Custom" || echo ""
}

if [ "$1" == "-h" ]
then
   usage
   exit 0
elif [ "$1" == "-r" ]
then
   RELEASE_MODE=1
elif [ "$1" == "-s" ]
then
   SONAR_MODE=1
elif [ $# -ne 0 ]
then
   infoLog "Bad argument count or invalid argument !"
   usage
   exit 1
fi

if [[ -n "$(isCustomProject)" ]]
then
   if [[ -z "$RELEASE_MODE" ]]
   then
      sh "${CUR_DIR}/build.sh"
   else
      sh "${CUR_DIR}/build.sh" -r
   fi
elif [[ -n "$(isMavenProject)" ]]
then
   buildProject "Maven"
elif [[ -n "$(isRpmProject)" ]]
then
   buildProject "Rpm"
else
   infoLog "Unknown project type - Aborting"
fi
