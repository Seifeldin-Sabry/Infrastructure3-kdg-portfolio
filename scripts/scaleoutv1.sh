#!/bin/bash

# Author: Seifeldin Sabry

# Function to create/delete a firewall rule and a VM instance
# Usage: ./pract7.sh [-d | -delete] to delete all VMs and the firewall rule
# Usage: ./pract7.sh to create a VM and a firewall rule with rocket chat installed

VM_NAME="instance-$(date +%s)"
PROJECT_ID="infra3-seifeldin-sabry"
MACHINE_TYPE="f1-micro"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
TARGET_PORT=tcp:3000
TARGET_TAGS="http-server,chat"

function check_rule_exists {
  # Check if a rule already exists
  rule=$1
  rule_tags=$2
  port=$3
  project=$4
  if gcloud compute firewall-rules list | grep -E "\b${port}\b" 2>/dev/null; then
    echo "Rule '${rule}' already exists"
  else
    TAGS=$(gcloud compute firewall-rules describe "${rule}" --quiet --format='flattened(targetTags)' | awk '{print $2}'  2>/dev/null)
    tags="${rule_tags} ${TAGS}"
    create_rule "${rule}" "${tags}" "${port}" "${project}"
  fi
}

check_rule_exists "rocket-chat" "chat" "${TARGET_PORT}" "${PROJECT_ID}"
check_rule_exists "http-server" "http-server" "tcp:80" "${PROJECT_ID}"
echo $TARGET_TAGS TARGET TAGS
gcloud compute instance-templates create "${VM_NAME}" \
  --project=${PROJECT_ID} \
  --machine-type=${MACHINE_TYPE} \
  --image-family=${IMAGE_FAMILY} \
  --image-project=${IMAGE_PROJECT} \
  --tags="${TARGET_TAGS}" \
  --metadata startup-script="#!/bin/bash
  	apt update
  	apt install apache2 -y"
