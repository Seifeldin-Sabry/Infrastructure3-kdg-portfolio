#!/bin/bash

#Function:  Replace spaces in file names with underscores.
#Name:      cutspace.sh

IFS='
'


# check if --help is supplied
if [ "$1" = "--help" ]; then
  echo -e "Usage: supply directory eg: 'cutspaces.sh <directory>'"
  echo -e "For testing, use 'cutspaces.sh --test'"
  echo -e "--test: Creates 10 files with random names and spaces in them"
  echo -e "make sure to run --test as root"
  echo -e "Note: directory must be supplied otherwise"
  echo -e "Changes all spaces in file names to underscores"
  exit 1
fi

createTestFiles()
{
  for i in {1..10}; do
    touch "$1/$RANDOM $RANDOM $RANDOM"
  done
}

fixFileNames()
{
  for file in $(find "$dir" -type f); do
    if [[ -f $file ]]; then
      mv "$file" "${file// /_}"
    fi
  done
}

if [ "$1" = "--test" ]; then
  if [ "$(id -u)" != "0" ]; then
    echo "Please run as root"
    exit 1
  fi
  dir="/tmp/test"
  mkdir -p "$dir"
  if [ "$(ls -A $dir)" ]; then
    rm -rf "$dir/*"
  fi
  createTestFiles "$dir"
  fixFileNames "$dir"
  echo "Done"
  exit 0
fi

dir=$1

# check if directory is supplied, just check if the variable is empty
if [ -z "$dir" ]; then
  echo "Please supply a directory, or use --help"
  exit 1
fi

fixFileNames "$dir"

unset IFS

echo "Done"