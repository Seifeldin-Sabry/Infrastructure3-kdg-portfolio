#!/bin/bash

# Author: Seifeldin Sabry
# Function: Create a VM that is connected to postgres14 db, create a user and a database


VM_NAME="instance-$(date +%s)"
PROJECT_ID="infra3-seifeldin-sabry"
ZONE="europe-west1-b"
MACHINE_TYPE="e2-small"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
DISK_TYPE="pd-standard"
DISK_SIZE="10GB"

IP_ADDRESS="$(curl -4 icanhazip.com --silent)/32" > /dev/null 2>&1

DB_TIER="db-f1-micro"
DB_VERSION="POSTGRES_14"
DB_CRED_USERNAME="postgres"
DB_NAME="$1"
DB_USER="$2"
DB_INSTANCE_NAME="gcloud4-4"
DB_STORAGE_SIZE=10


# check if --help or -h flag is passed
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: create a VM that is connected to porstgres14 db"
  echo "Parameters:"
  echo "1) db_name: name of the database"
  echo "2) db_user: name of the user"
  echo "required"
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

#check if the name of the database is passed
if [[ -z "${DB_NAME}" ]]; then
  echo "Please pass the name of the database"
  exit 1
fi

#check if the name of the user is passed
if [[ -z "${DB_USER}" ]]; then
  echo "Please pass the name of the user"
  exit 1
fi

# check if the database instance exists
if ! gcloud sql instances describe "${DB_INSTANCE_NAME}" &> /dev/null; then
  echo "The database instance does not exist"
  exit 100
fi

gcloud compute instances create "${VM_NAME}" \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  --machine-type=${MACHINE_TYPE} \
  --image-family=${IMAGE_FAMILY} \
  --image-project=${IMAGE_PROJECT} \
  --boot-disk-type=${DISK_TYPE} \
  --boot-disk-size=${DISK_SIZE} \
  --metadata startup-script="#!/bin/bash
  	apt-get update && apt-get install -y postgresql-client"

IP_ADDRESS_VM="$(gcloud compute instances list --format='table(EXTERNAL_IP)' --filter="name:${VM_NAME}" | tail -n1)/32"
existing_authorised_networks="$(gcloud sql instances describe ${DB_INSTANCE_NAME} --format="value(settings.ipConfiguration.authorizedNetworks.value)" | tr ';' ',')"

for ip in ${existing_authorised_networks}; do
  if [[ -n "${ip}" ]]; then
    IP_ADDRESS_VM="${IP_ADDRESS_VM},${ip}/32"
  fi
done

gcloud sql instances patch "${DB_INSTANCE_NAME}"  --authorized-networks="${IP_ADDRESS_VM}" --quiet > /dev/null 2>&1

if gcloud sql users list --instance="${DB_INSTANCE_NAME}" --format="table(name)" | grep -q "${DB_USER}"; then
  echo "The user exists, skipping..."
else
  read -rsp 'Enter password for the user:' USER_PASS
  gcloud sql users create "${DB_USER}" --password="${USER_PASS}" --instance="${DB_INSTANCE_NAME}"
fi

if gcloud sql databases list --instance="${DB_INSTANCE_NAME}" --format="table(name)" | grep -q "${DB_NAME}"; then
  echo "The database exists, skipping..."
else
  gcloud sql databases create "${DB_NAME}" --instance="${DB_INSTANCE_NAME}"
fi
