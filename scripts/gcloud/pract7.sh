#!/bin/bash

# Author: Seifeldin Sabry

# Function to create/delete a firewall rule and a VM instance
# Usage: ./pract7.sh [-d | -delete] to delete all VMs and the firewall rule
# Usage: ./pract7.sh to create a VM and a firewall rule with rocket chat installed

VM_NAME="instance-$(date +%s)"
PROJECT_ID="infra3-seifeldin-sabry"
ZONE="europe-west1-b"
MACHINE_TYPE="e2-medium"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
TARGET_TAGS="chat"
HTTP_RULE_NAME="rocket-chat"
TARGET_PORT=tcp:3000

# check if --help or -h flag is passed
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: ./pract7.sh [-d | -delete] to delete all VMs and the firewall rule"
  echo "Usage: ./pract7.sh to create a VM and a firewall rule with rocket chat installed"
  exit 0
fi

# check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
  echo "gcloud could not be found please install it first"
  exit 1
fi

#check if -d or -delete flag is passed
if [[ "$1" == "-d" || "$1" == "-delete" ]]; then
  vms=$(gcloud compute instances list --format='table[no-heading](name)' --filter=${TARGET_TAGS})
  for vm in $vms; do
    gcloud compute instances delete "${vm}" --quiet
  done
  gcloud compute firewall-rules describe "rocket-chat" >/dev/null  && echo "Deleting firewall rule..." && gcloud compute firewall-rules delete "rocket-chat" --quiet
  echo "VMs and firewall rule deleted"
  exit 0
fi

function create_rule {
  rule=$1
  tags=$2
  port=$3
  project=$4
  gcloud compute firewall-rules create "${rule}" --project="${project}" --allow="${port}" --target-tags="${tags}"
  echo "Rule '${HTTP_RULE_NAME}' created"
}

function check_rule_exists {
  # Check if a rule already exists
  rule=$1
  port=$2
  if gcloud compute firewall-rules list | grep -E "\b${port}\b" >/dev/null; then
    echo "Rule '${rule}' already exists, appending target tags..."
    TARGET_TAGS="$(gcloud compute firewall-rules describe "${rule}" --format='flattened(targetTags)' | awk '{print $2}') ${TARGET_TAGS}"
  else
    create_rule "${HTTP_RULE_NAME}" "${TARGET_TAGS}" "${TARGET_PORT}" "${PROJECT_ID}"
  fi
}
check_rule_exists "${HTTP_RULE_NAME}" "${TARGET_PORT}"
# Create VM instance
gcloud compute instances create "${VM_NAME}" \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  --machine-type=${MACHINE_TYPE} \
  --image-family=${IMAGE_FAMILY} \
  --image-project=${IMAGE_PROJECT} \
  --metadata startup-script="#!/bin/bash
  	apt update
  	snap install rocketchat-server" \
  --tags="${TARGET_TAGS}"

