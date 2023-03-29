#!/bin/bash

# Author: Seifeldin Sabry
# Function: Find which process uses a certain port

function usage() {
  echo \
"Warning:     execute this script as root or with sudo permissions.
Description: This script displays which process uses a certain port.
Usage:       sudo netcat.sh [OPTIONS]

OPTIONS:
-h, --help      Display these instructions
-t, --testing   Start a listening port on 13 with 'netcat'
no option       Execute this script"
  exit 1
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

function isTesting() {
  if [[ "$1" == "--testing" || "$1" == "-t" ]]; then
    return 0
  fi
  return 1
}

function checkDependencies() {
  local dependencies=("$@") # Store all arguments in an array
  local missing=() # Initialize an empty array to store missing dependencies

  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then # Check if the dependency is installed
      missing+=("$dep") # Add to missing array if not installed
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then # Check if the missing array is not empty
    error "The following dependencies are missing: ${missing[*]}"
    exit 1
  fi
}

checkHelp "$1"
checkRoot
checkDependencies "netcat"

if isTesting "$1"; then
  echo "Start a listening port on 13"
  echo "with netcat (option -l)"
  echo "nc -l 13 &"
  nc -l 13 &
  sudo lsof -nPi tcp:13 | grep -i listen
fi


