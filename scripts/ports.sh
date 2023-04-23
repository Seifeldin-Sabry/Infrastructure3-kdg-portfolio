#!/bin/bash

# Author: Seifeldin Sabry
# Function: Find which process uses a certain port
REGEX="\w+\s+\w+\s+\w+\s+[0-9 \.]+:(c[0-9]+)"



function usage() {
  echo \
"Warning:     execute this script as root or with sudo permissions.
Description: This script displays which process uses a certain port.
Usage:       sudo ports.sh
"
  exit 0
}

function error() {
  echo "Error: $1"
}

function checkRoot() {
  if [ "$(id -u)" != "0" ]; then
    error "Please run as root"
    exit 1
  fi
}

function checkHelp() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    usage
  fi
}

function printPort(){
  [[ $1 =~ $REGEX ]]
  port="${BASH_REMATCH[1]}"
  echo "The port $port is used"
}

checkHelp "$1"
checkRoot

for port in $(netstat -tulpn | grep -i listen); do
  echo "$port"
  printPort "$port"
done

