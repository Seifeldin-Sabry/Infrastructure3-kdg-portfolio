#!/bin/bash
reset='[0m'
red='[0;31m'

function checkRoot() {
  if [ "$(id -u)" != "0" ]; then
    error "Please run as root"
    exit 1
  fi
}

function showcolorized {
  echo -e "\e$red $1 \e$reset"
}

function checkHelp() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << EOF
    Warning:     execute this script as root or with sudo permissions.
    Description: This script displays which process uses a certain port.
    Usage:       sudo netcat.sh [OPTIONS]

    OPTIONS:
    -h, --help      Display these instructions
    -t, --testing   Start a listening port on 13 with 'netcat'
    no option       Execute this script
EOF
    exit 1
  fi
}


function isTesting() {
  if [[ "$1" == "--testing" || "$1" == "-t" ]]; then
    return 0
  fi
  return 1
}

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

function create_rule {
  rule=$1
  tags=$2
  port=$3
  gcloud compute firewall-rules create "${rule}" --allow="${port}" --target-tags="${tags}"
  echo "Rule '${HTTP_RULE_NAME}' created"
}

function check_rule_exists {
  # Check if a rule already exists
  rule=$1
  rule_tags=$2
  port=$3
  project=$4
  if gcloud compute firewall-rules list | grep -E "\b${port}\b" 2>/dev/null; then
    echo "Rule '${rule}' already exists"
    TARGET_TAGS="$(gcloud compute firewall-rules describe "${rule}" --quiet --format='flattened(targetTags)' | awk '{print $2}'  2>/dev/null),${TARGET_TAGS}"
  else
    TAGS=$(gcloud compute firewall-rules describe "${rule}" --quiet --format='flattened(targetTags)' | awk '{print $2}'  2>/dev/null)
    tags="${rule_tags} ${TAGS}"
    create_rule "${rule}" "${tags}" "${port}" "${project}"
  fi
}

function error() {
  echo "Error: $1" >&2
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

function create_vm() {
  gcloud compute instances create "${VM_NAME}" \
    --zone=${ZONE} \
    --machine-type=${MACHINE_TYPE} \
    --image-family=${IMAGE_FAMILY} \
    --image-project=${IMAGE_PROJECT} \
    --metadata startup-script="#!/bin/bash
    	apt update
    	snap install rocketchat-server" \
    --tags="${TARGET_TAGS}"
}