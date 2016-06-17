#!/bin/bash

SCRIPT_NAME=$(basename $0)

usage() 
{
   cat >&2 <<-EOF

   USAGE : $SCRIPT_NAME <spec_file_name>

   Create a RPM from what has been specified in file spec_file_name. File
   spec_file_name must be located in a subdirectory of the current directory.
   The resulting RPM is put under directory $(pwd)/target/results


EOF  
}


