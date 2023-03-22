#!/bin/bash

# Author: Seifeldin Sabry

#Create a VM on Gcloud with Apache2 installed (or use an existing VM, if available). Use a simple webpage.
#Enable the local Ubuntu firewall.
#Warning: don’t close the session or you’ll lock yourself out!
#Check if the webpage is still accessible.
#
#Required:
#Open up ports 22 and 80 in the firewall
#Check that the website is available.


VM_NAME="instance-$(date +%s)"
ZONE="europe-west1-b"
MACHINE_TYPE="e2-small"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
DISK_TYPE="pd-standard"
DISK_SIZE="10GB"

# check if --help or -h flag is passed
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: create a VM n gcloud with apache2 installed"
  exit 0
fi

# check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
  echo "gcloud could not be found please install it first"
  echo "Parameters:"
  echo "1) db_name: name of the database"
  echo "2) db_user: name of the user"
  echo "required"
  exit 1
fi

gcloud compute instances create "${VM_NAME}" \
  --zone=${ZONE} \
  --machine-type=${MACHINE_TYPE} \
  --image-family=${IMAGE_FAMILY} \
  --image-project=${IMAGE_PROJECT} \
  --boot-disk-type=${DISK_TYPE} \
  --boot-disk-size=${DISK_SIZE} \
  --metadata startup-script="#!/bin/bash
  	apt-get update && apt install -y apache2
  	ufw allow 80/tcp
  	ufw allow 22/tcp
  	ufw enable
  	"