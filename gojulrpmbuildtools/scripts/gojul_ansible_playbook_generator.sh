#!/bin/bash

set -e

SCRIPT_NAME=$(basename $0)

ANSIBLE_TEMPLATES_DIR="ansibleTemplates/"
ANSIBLE_MAPPINGS="${ANSIBLE_TEMPLATES_DIR}/ansible_mappings.txt"

# Print a usage hint on this script
usage()
{
   cat >&2 <<-EOF

   USAGE: $SCRIPT_NAME [-h] <moduleName> <version>

   This script generates an Ansible playbook if it finds under the
   current directory the file ansibleTemplates/ansible_mappings.txt.

   Its purpose is to be used with auto-generated spring boot RPM packages
   and other stuff like this.

   This file must be structured as follows :
   <templateName>=<destinationFile>

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

   mkdir -p ansible/meta
   cat >ansible/meta/main.yml <<-EOF
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
# - the line to process
addTemplateLine()
{
   local moduleName="$1"
   local lineToProcess=$(echo "$2"|sed -e 's/\s*#.*//g')

   [ -n "$lineToProcess" ] || return 0

   local templateFile=$(echo "$lineToProcess"|cut -d= -f1)
   local targetFile=$(echo "$lineToProcess"|cut -d= -f2)

   cp "${ANSIBLE_TEMPLATES_DIR}/${templateFile}" "ansible/roles/${moduleName}/templates"

   cat >>$(getTasksFile "$moduleName") <<-EOF
- name: Upload file $targetFile for package $moduleName
  template:
    src: $templateFile
    dest: $targetFile

EOF
}

# Generate the configuration template lines
# PARAMS:
# - the module name
generateConfigTemplates()
{
  local moduleName="$1"

  [ -f "$ANSIBLE_MAPPINGS" ] || return 0

  cat "$ANSIBLE_MAPPINGS" | while read line
  do
     addTemplateLine "$moduleName" "$line"
  done
}



createPlaybookBasicStructure "$1"
generateInstallLine "$1" "$2"
generateConfigTemplates "$1"
