#!/bin/bash

SCRIPT_NAME=$(basename $0)

set -e

usage()
{
  cat >&2 <<-EOF

     USAGE: $SCRIPT_NAME

     This script looks for every spec file which is located
     exactly one directory level below the current directory.
     For each of the found spec files it creates an RPM which
     is located under $(pwd)/target/results

EOF
}

if [ "$1" == "-h" ]
then
   usage
   exit 0
elif [ $# -ne 0 ]
then
   echo >&2 "This script does not take any argument !"
   usage
   exit 1
fi

rm -rf $(pwd)/target

for i in $(find . -mindepth 2 -maxdepth 2 -name "*.spec")
do
    $(dirname $0)/build_package.sh $i
done
