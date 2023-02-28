#!/bin/bash

# Define variables
VM_NAME="instance-$(date +%s)"
PROJECT_ID="infra3-seifeldin-sabry"
ZONE="europe-west1-b"
MACHINE_TYPE="e2-small"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
TARGET_TAGS="web-server"
HTTP_RULE_NAME="http-server"
TARGET_PORT=tcp:80


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
  if gcloud compute firewall-rules list | grep -E "\b${port}\b"; then
    echo "Rule '${rule}' already exists"
    TARGET_TAGS=$(gcloud compute firewall-rules describe "${rule}" --format='flattened(targetTags)' | awk '{print $2}')
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
  --tags="${TARGET_TAGS}"
