#! /bin/bash

#Create a subdomain on https://duckdns.org.
#Add a oneliner to an existing VM with a web server
# so that its webpage is accessible by name on standard port 80,
# no matter what the IP address is.
PROJECT_ID="infra3-seifeldin-sabry"
VM_NAME="instance-$(date +%s)"
ZONE="europe-west1-b"
MACHINE_TYPE="e2-small"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
DISK_TYPE="pd-standard"
DISK_SIZE="10GB"
DUCK_TOKEN=2836d713-b14a-404a-83ee-6d67c4f93d86
DUCK_DNS=seifsabry

# check if --help or -h flag is passed
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: create a VM n gcloud with apache2 installed"
  exit 0
fi

# check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
  echo "gcloud could not be found please install it first"
  exit 1
fi

function create_rule {
  rule=$1
  tags=$2
  port=$3
  project=$4
  gcloud compute firewall-rules create "${rule}" --project="${project}" --allow="${port}" --target-tags="${tags}"
  echo "Rule '${HTTP_RULE_NAME}' created"
}

gcloud compute instances create "${VM_NAME}" \
  --zone=${ZONE} \
  --machine-type=${MACHINE_TYPE} \
  --image-family=${IMAGE_FAMILY} \
  --image-project=${IMAGE_PROJECT} \
  --boot-disk-type=${DISK_TYPE} \
  --boot-disk-size=${DISK_SIZE} \
  --tags=http-server \
  --metadata startup-script="#!/bin/bash
  	apt-get update && apt install -y apache2
  	echo \"<!doctype html><html><head><title>My first web page</title></head><body><h1>Hello world!</h1></body></html>\" > /var/www/html/index.html
  	ufw allow 80/tcp
  	ufw allow 22/tcp
  	ufw enable
  	"

while true; do
#  if gcloud status then break
  if gcloud compute instances describe "${VM_NAME}" --format='value(status)' | grep -q "RUNNING"; then
    break
  fi
  echo "Waiting for VM to be ready"
  sleep 5
done
EXTERNAL_IP=$(gcloud compute instances describe "${VM_NAME}" --format='value(networkInterfaces[0].accessConfigs[0].natIP)')
duckdns="https://www.duckdns.org/update?domains=${DUCK_DNS}&token=${DUCK_TOKEN}&ip=${EXTERNAL_IP}"
curl -k "${duckdns}"