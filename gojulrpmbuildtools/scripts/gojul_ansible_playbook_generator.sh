#!/bin/bash

set -e

SCRIPT_NAME=$(basename $0)

ANSIBLE_TEMPLATES_DIR="ansibleTemplates/"

# Print a usage hint on this script
usage()
{
   cat >&2 <<-EOF

   USAGE: $SCRIPT_NAME [-h] <moduleName> <version>

   This script generates an Ansible playbook if it finds under subdirectory
   $ANSIBLE_TEMPLATES_DIR template files.

   The $ANSIBLE_TEMPLATES_DIR directory must contain at least one of the following
   directories :
   - appSettings : the application settings, which go under /etc/gojuldaemons/<module_name>/
   - sysconfig : the daemon configuration for SpringBoot daemons, which go under /etc/sysconfig/gojuldaemons.
   Note that you should only put one file per daemon, which actually matches the daemon name.
   - systemd : the SystemD configuration files, whih go under /etc/systemd/system/<module_name>.service.d/

   It takes the following parameters into account :
   - -h : print this help message
   - moduleName : the module name for this playbook
   - version: the module version for this playbook

   This program adds the playbook to the local git repo as well.

EOF
}

# Print a log message.
# PARAMS
# - the message to display
infoLog()
{
   echo >&2 "$1"
}

# Exit this program with an error message
# PARAMS
# - the message to display
die()
{
   infoLog "$1"
   exit 255   
}

# Create the playbook basic structure.
# PARAMS :
# - the module name
createPlaybookBasicStructure()
{
   local moduleName="$1"

   mkdir -p ansible/roles/${moduleName}/{tasks,templates,defaults}
   cat >ansible/playbook.yml <<-EOF
- hosts: $moduleName
  roles:
  - { role: $moduleName }
EOF

   touch ansible/.playbook_gojul_generated

   cat >"ansible/roles/${moduleName}/defaults/main.yml" <<-EOF
auto_start_services: true
EOF

   mkdir -p meta
   cat >meta/main.yml <<-EOF
john: smith
EOF

}

# Return the name of the tasks file
# PARAMS :
# - the module name
getTasksFile()
{
   echo "ansible/roles/${1}/tasks/main.yml"
}

# Generate the package installation line
# PARAMS :
# - the module name
# - the module version
generateInstallLine()
{
   local moduleName="$1"
   local moduleVersion="$2"

   cat >$(getTasksFile "$moduleName") <<-EOF

- name: Install package $moduleName
  yum:
    name: "${moduleName}-${moduleVersion}"
    state: present

EOF
}

# Add a package template line
# PARAMS :
# - the module name
# - the template file
# - the remote target path 
addTemplateLine()
{
   local moduleName="$1"
   local templateFile="$2"
   local targetPath="$3"

   cp "${templateFile}" "ansible/roles/${moduleName}/templates"

   local targetFile="${targetPath}/$(basename $templateFile .j2)"

   cat >>$(getTasksFile "$moduleName") <<-EOF
- name: Upload file $targetFile for package $moduleName
  template:
    src: $(basename $templateFile)
    dest: $targetFile

EOF
}

# Add template lines for all
# the files located under the directory
# specified under the directory specified.
# PARAMS :
# - the module name
# - the source directory
# - the remote target path
addTemplateLines()
{
   local moduleName="$1"
   local sourceDir="$2"
   local targetPath="$3"

   [ -d "$sourceDir" ] || return 0

   for i in $(ls "$sourceDir")
   do
      addTemplateLine "$moduleName" "${sourceDir}/${i}" "$targetPath"
   done
}

# Generate the configuration template lines
# PARAMS:
# - the module name
generateConfigTemplates()
{
   local moduleName="$1"

   addTemplateLines "$moduleName" "${ANSIBLE_TEMPLATES_DIR}/appSettings" "/etc/gojuldaemons/${moduleName}"
   addTemplateLines "$moduleName" "${ANSIBLE_TEMPLATES_DIR}/sysconfig" "/etc/sysconfig/gojuldaemons"
   addTemplateLines "$moduleName" "${ANSIBLE_TEMPLATES_DIR}/systemd" "/etc/systemd/system/${moduleName}.service.d"

}

# Generate the service line
# PARAMS:
# - the module name
generateServiceLine()
{
   local moduleName="$1"

   cat >>$(getTasksFile "$moduleName") <<-EOF
- name: Start service $moduleName
  service:
    name: $serviceName
    enabled: yes
    state: started
  when: auto_start_services  
EOF
}

# Generate the whole playbook.
# PARAMS:
# - the module name
# - the module version
generatePlaybook()
{
   local moduleName="$1"
   local moduleVersion="$2"

   createPlaybookBasicStructure "$moduleName"
   generateInstallLine "$moduleName" "$moduleVersion"
   generateConfigTemplates "$moduleName"
   generateServiceLine "$moduleName"

   if [ -f .git/config ]
   then
      git add ansible meta
   fi
}

if [ "$1" == "-h" ]
then
   usage
   exit 0
elif [ $# -ne 2 ]
then
   usage
   die "Bad argument count !"
fi

if [ -d ansible ]
then
   infoLog "A playbook already exists for this module - skipping generation"
   exit 0
fi
[ -d "$ANSIBLE_TEMPLATES_DIR" ] || {
   infoLog "No directory $ANSIBLE_TEMPLATES_DIR found - assuming this module does not need a playbook"
   exit 0
}

generatePlaybook "$1" "$2"

