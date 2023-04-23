#!/bin/bash

VM_NAME="exam-$(date +%s)"
ZONE="europe-west1-b"
MACHINE_TYPE="e2-small"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
TARGET_TAGS="http-server,allow-ssh,ssl-rule-tag"

DUCK_TOKEN=2836d713-b14a-404a-83ee-6d67c4f93d86
DUCK_DNS=infra3413

HTTP_RULE_NAME="http-rule"
HTTP_RULE_PORT="80"

SSL_RULE_NAME="ssl-rule-2"
SSL_RULE_PORT="443"

SSH_RULE_NAME="ssh-rule"
SSH_RULE_PORT="22"

EMAIL=seifeldin.sabry@student.kdg.be

function checkHelp() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << EOF
    Description: This script makes a VM in gcloud with apache2 installed and https enabled
    Usage:       exam.sh
    WARNING: change your email, duckdns token and dns name
EOF
    exit 1
  fi
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
    TARGET_TAGS="${TARGET_TAGS},$(gcloud compute firewall-rules describe "${rule}" --quiet --format='flattened(targetTags)' | awk '{print $2}'  2>/dev/null)"
    echo "TARGET_TAGS: ${TARGET_TAGS}"
  else
    TAGS=$(gcloud compute firewall-rules describe "${rule}" --quiet --format='flattened(targetTags)' | awk '{print $2}'  2>/dev/null)
    tags="${rule_tags} ${TAGS}"
    create_rule "${rule}" "${tags}" "${port}" "${project}"
  fi
}



function create_vm() {
  gcloud compute instances create "${VM_NAME}" \
    --zone=${ZONE} \
    --machine-type=${MACHINE_TYPE} \
    --image-family=${IMAGE_FAMILY} \
    --image-project=${IMAGE_PROJECT} \
    --metadata startup-script="#!/bin/bash
    	apt-get update && apt-get -y install apache2
      systemctl enable apache2
      systemctl start apache2
      ufw allow 80/tcp
      ufw allow 443/tcp
      ufw allow 22/tcp
      ufw allow \"Apache Full\"
      ufw enable
      echo '<!doctype html><html><head><title>My first web page</title></head><body><h1>this is a test page</h1></body></html>' > /var/www/html/index.html
      snap install core
      snap refresh core
      snap install --classic certbot
      ln -s /snap/bin/certbot /usr/bin/certbot
      certbot --non-interactive --apache -d $DUCK_DNS.duckdns.org --agree-tos --email $EMAIL
      systemctl restart apache2
      curl -k \"https://www.duckdns.org/update?domains=$DUCK_DNS&token=$DUCK_TOKEN&ip=\"" \
    --tags="http-server,allow-ssh,ssl-rule-tag"
}
checkHelp "$1"
checkDependencies "gcloud"
check_rule_exists "${HTTP_RULE_NAME}" "http-server" "${HTTP_RULE_PORT}"
check_rule_exists "${SSL_RULE_NAME}" "ssl-rule-tag" "${SSL_RULE_PORT}"
check_rule_exists "${SSH_RULE_NAME}" "allow-ssh" "${SSH_RULE_PORT}"
create_vm