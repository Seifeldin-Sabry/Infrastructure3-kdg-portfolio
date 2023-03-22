#!/bin/bash

PROJECT_ID="infra3-seifeldin-sabry"
VM_NAME="instance-$(date +%s)"
ZONE="europe-west1-b"
MACHINE_TYPE="e2-small"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
DISK_TYPE="pd-standard"
DISK_SIZE="10GB"
DUCK_TOKEN=2836d713-b14a-404a-83ee-6d67c4f93d86
DUCK_DNS=seifeldin-infra3
HTTP_RULE_NAME="four-four-three"
TARGET_TAGS="http-server,ssl-rule-tag"
EMAIL=seifeldin.sabry@student.kdg.be

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
function create_rule {
  rule=$1
  tags=$2
  port=$3
  project=$4
  gcloud compute firewall-rules create "${rule}" --project="${project}" --allow="${port}" --target-tags="${tags}"
  echo "Rule '${rule}' created"
}

function check_rule_exists {
  # Check if a rule already exists
  rule=$1
  rule_tags=$2
  port=$3
  project=$4
  if gcloud compute firewall-rules list | grep -E "\b${port}\b" >/dev/null; then
    echo "Rule '${rule}' already exists"
    TARGET_TAGS=$(gcloud compute firewall-rules describe "${rule}" --format='flattened(targetTags)' | awk '{print $2}')
  else
    create_rule "${rule}" "${rule_tags}" "${port}" "${project}"
  fi
}

check_rule_exists "ssl-rule-2" "ssl-rule-tag" "443" "${PROJECT_ID}"
check_rule_exists "http-rule" "http-server" "80" "${PROJECT_ID}"

gcloud compute instances create "${VM_NAME}" \
  --zone=${ZONE} \
  --machine-type=${MACHINE_TYPE} \
  --image-family=${IMAGE_FAMILY} \
  --image-project=${IMAGE_PROJECT} \
  --boot-disk-type=${DISK_TYPE} \
  --boot-disk-size=${DISK_SIZE} \
  --tags=http-server,ssl-rule-tag \
  --metadata startup-script="#!/bin/bash
  	apt-get update && apt install -y apache2
  	echo \"<!doctype html><html><head><title>My first web page</title></head><body><h1>Hello world!</h1></body></html>\" > /var/www/html/index.html
  	ufw allow 80/tcp
  	ufw allow 443/tcp
  	ufw allow 22/tcp
  	ufw allow \"Apache Full\"
  	ufw enable
  	snap install core; snap refresh core
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot
    curl -k https://www.duckdns.org/update?domains=\"${DUCK_DNS}\"&token=\"${DUCK_TOKEN}\"&txt=\"${DUCK_TOKEN}\"&ip=
    sudo certbot -n -d ${DUCK_DNS}.duckdns.org --agree-tos -m ${EMAIL} --apache
    systemctl restart apache2
  	"