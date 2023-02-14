#!/bin/bash

#Function:  Replace spaces in file names with underscores.
#Name:      cutspace.sh

# check if --help is supplied
if [ "$1" = "--help" ]; then
  echo -e "Usage: supply directory eg: 'cutspaces.sh <directory>'"
  echo -e "Note: directory must be supplied"
  echo -e "Changes all spaces in file names to underscores"
  exit 1
fi

dir=$1

# check if directory is supplied, just check if the variable is empty
if [ -z "$dir" ]; then
  echo "Please supply a directory, or use --help"
  exit 1
fi

# check if directory exists
if [ ! -d "$dir" ]; then
  echo "Directory does not exist, creating directory"
  mkdir -p "$dir"
fi

#create 10 files with random names and spaces in them, using $RANDOM
for i in {1..10}; do
  touch "$dir"/"$RANDOM $RANDOM $RANDOM"
done

# replace the file names spaces with underscores
for file in "$dir"/*; do
  if [[ -f $file ]]; then
    mv "$file" "${file// /_}"
  fi
done

echo "Done"