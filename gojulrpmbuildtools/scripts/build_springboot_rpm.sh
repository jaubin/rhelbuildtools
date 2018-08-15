#!/bin/bash

SCRIPT_NAME=$(basename $0)
SPRINGBOOT_RPM_TEMPLATES="/usr/share/gojulrpmbuildtools/springboot"
rpmResultDir=$(pwd)/target/rpmResults

set -e

usage()
{
   cat >&2 <<-EOF
  
      USAGE: $SCRIPT_NAME

      This script must be executed under a directory where a Maven
      pom.xml file is present.

      It looks for any SpringBoot JAR file found under the current directory
      and creates a RPM package for each of them. These files end with the -spring-boot.jar
      extension, so beware not to configure the spring-boot plugin to give them a fancy name. 
      However it is a good idea to set up a build final name for this JAR. Each of the generated 
      RPM files must be directly under Maven's target/ directory. 

      If your SpringBoot JAR has configuration files they must be put under directory
      target/../src/main/configApps/<jarname_without_spring-boot-ext>. The tool will declare them
      as RPM configuration files and package them under directory
      /etc/springboot/<jar-name>/

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

# Find all the SpringBoot JAR files under the current directory
# RETURNS
# - the list of SpringBoot JAR files under the current directory
findSpringBootJars()
{
   find . -name "*-spring-boot.jar"
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

# Return the JAR name without extension of the WAR file
# given as a parameter.
# PARAMS :
# - jarFile : the jar file path.
# RETURNS :
# - the war name corresponding to jarFile
getSpringBootJarName()
{
  local jarFile="$1"
  local res=$(basename $jarFile "-spring-boot.jar")
  [[ -z "$res" ]] && exitWithError "File $jarFile does not seem to be a valid SpringBoot JAR" 1
  echo $res
}

# Extract the Spring Boot version from the pom.xml
# in the current directory
getSpringBootJarVersion()
{
  mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec | sed -e "s/-/_/g"
}

# Return the RPM spec file name with
# its path corresponding to the SpringBoot file
# jarFile
# PARAMS :
# - jarFile : the jar file.
getSpecFileName()
{
  local jarFileName="$@"
  local jarName=$(getSpringBootJarName $jarFileName)
  echo "$(getRpmWorkDir)/SPECS/${warName}.spec"
}

# Prepare the RPM spec file which corresponds
# to the JAR file passed as a parameter.
# PARAMS :
# - jarFileName : the JAR file name.
prepareSpecFile()
{
  local jarFileName="$@"
  local jarName=$(getSpringBootJarName $jarFileName)
  local targetSpecFile=$(getSpecFileName "$jarFileName")

  cp $SPRINGBOOT_RPM_TEMPLATES/springboot_spec_file_template.spec $targetSpecFile

  sed -i "s/@@JARNAME@@/$jarName/g" $targetSpecFile
  sed -i "s/@@JARVERSION@@/$(getSpringBootJarVersion)/g" $targetSpecFile
}


# Return the configApps work directory
# PARAMS :
# - the JAR file name
# RETURNS :
# - the configApps source directory
getConfigAppsDir()
{
  local jarFile="$1"
  local jarName=$(getSpringBootJarName "$jarFile")

  echo "$(getRpmWorkSourceDir)/configApps"
}

# Copy the default logback.xml
# if necessary, i.e. if the app
# does not already defines another one.
# PARAMS :
# - the JAR file name
copyLogConfigIfNecessary()
{
   local jarFile="$1"
   local configAppsDir=$(getConfigAppsDir "$jarFile")
   local targetLogConfig="${configAppsDir}/logback.xml"

   if [ ! -f $targetLogConfig ]
   then
      local jarName=$(getSpringBootJarName "$jarFile")
      cp $SPRINGBOOT_RPM_TEMPLATES/logback_template.xml $targetLogConfig
      sed -i "s/@@JARNAME@@/$jarName/g" $targetLogConfig
   fi
}

# Update the application.properties file
# so that it matches our settings.
# PARAMS :
# - the JAR file name
createOrUpdateApplicationProperties()
{
   local jarFile="$1"
   local jarName="$(getSpringBootJarName $jarFile)"
 
   local applicationProperties="$(getConfigAppsDir $jarFile)/application.properties"
   local logbackTargetLocation="/etc/springboot/${jarName}/logback.xml"
   local logbackFullLine="logging.config=$logbackTargetLocation"

   if [ -f "$applicationProperties" ]
   then
       grep -e "^logging.config=" "$applicationProperties" > /dev/null && sed -i "s!^logging.config=.*!${logbackFullLine}!g" "$applicationProperties" || echo -e "\n\n${logbackFullLine}" >> "$applicationProperties"
   else
       echo "$logbackFullLine" >> "$applicationProperties"
   fi    
}

# Prepare the configApps directory for JAR file
# jarFile
# PARAMS :
# - the JAR file name
prepareConfigApps()
{
   local jarFile="$1"
   local jarName="$(getSpringBootJarName $jarFile)"
 
   local sourceConfigAppsDir="$(dirname $jarFile)/../src/main/configApps/$jarName"
   local globalTargetConfigAppsDir="$(getRpmWorkSourceDir)/configApps"

   mkdir -p $globalTargetConfigAppsDir
 
   if [ -d "$sourceConfigAppsDir" ]
   then
      cp -r $sourceConfigAppsDir/* $globalTargetConfigAppsDir
   else
      mkdir -p $globalTargetConfigAppsDir
   fi

   copyLogConfigIfNecessary "$jarFile"
   createOrUpdateApplicationProperties "$jarFile"
}

# Prepare the daemon script for JAR fiel jarFile
# PARAMS :
# - the JAR file name 
prepareDaemon()
{
   local jarFile="$1"
   local jarName="$(getSpringBootJarName $jarFile)"
 
   local targetDaemonFile="$(getRpmWorkSourceDir)/${jarName}"

   cp "$SPRINGBOOT_RPM_TEMPLATES/daemon_template" "$targetDaemonFile"

   sed -i "s/@@JARNAME@@/$jarName/g" $targetDaemonFile

   local targetSysconfigFile="$(getRpmWorkSourceDir)/sysconfig"

   cp "$SPRINGBOOT_RPM_TEMPLATES/sysconfig_template" "$targetSysconfigFile"

   sed -i "s/@@JARNAME@@/$jarName/g" $targetSysconfigFile

}

# Prepare the tgz archive which will be the source.
# PARAMS : 
# - the jar file name
prepareArchive()
{
   local jarFile="$1"
   local jarName=$(getSpringBootJarName "$jarFile")

   local curDir=$(pwd)
   cd $(getRpmWorkSourceDir)

   tar zcf ${jarName}.tgz configApps "$jarName" sysconfig "${jarName}-spring-boot.jar"
   rm -rf configApps "$jarName" sysconfig "${jarName}-spring-boot.jar"

   cd $curDir
}

# Create directory structure and copy files to the RPM directory structure
# PARAMS :
# - jarName : the JAR file name with its path
createDirectoriesAndRpmBuildFiles()
{
   local jarFileName="$1"

   createTargetDirectoryLayout
   prepareSpecFile "$jarFileName"

   cp $jarFileName $(getRpmWorkSourceDir)

   prepareConfigApps "$jarFileName"
   prepareDaemon "$jarFileName"

   prepareArchive "$jarFileName"
}

# Create a RPM for the JAR file passed as a parameter.
# PARAMS :
# - jarFile the JAR file for which a RPM must be created
createRpmForJar()
{
   local jarFileName="$1"
   local workDir=$(getRpmWorkDir)

   infoLog "Creating RPM package for file $jarFileName"

   createDirectoriesAndRpmBuildFiles "$jarFileName"
   rpmbuild --define "_topdir $workDir" --define "debug_package %{nil}" -ba $(getSpecFileName $jarFileName)

   mkdir -p $rpmResultDir || true

   for i in $(find $workDir/RPMS -name "*.rpm")
   do 
      cp $i $rpmResultDir
   done

   infoLog "RPM package create for file $jarFileName and available under $rpmResultDir"
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

for i in $(findSpringBootJars)
do
   createRpmForJar $i
done
