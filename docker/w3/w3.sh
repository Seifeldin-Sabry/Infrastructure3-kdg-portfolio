#!/bin/bash

#------------------------------------------------------------------------------
#- Name         : w3.sh
#- Author       : Seifeldin Sabry
#- Commit       : wordpress environment on gcloud
#- Descr        : wordpress environment on gcloud
#- Usage        : w3.sh <DB_INSTANCE> [-d | --delete] | -h|--help
#-Run Instructions:
#- run the script with the db instance name as an argument, to delete the instance add -d or --delete
#------------------------------------------------------------------------------

function check_help() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << EOF
    Description: This script makes a VM in gcloud with a docker container and hosts a wordpress site.
    Usage:       $(basename "$0") <DB_INSTANCE> [-d|--delete]
    -            $(basename "$0") -h|--help
EOF
    exit 1
  fi
}

function check_delete() {
  local db_user=$3
  local db_name=$4
  local db_srv=$5
  if [[ "$2" == "--delete" || "$2" == "-d" ]]; then
      echo "Deleting everything..."
      # Delete the database
      echo "Deleting database: $db_name"
      gcloud sql databases delete "$db_name" --instance="$db_srv" -q
#      Delete the database user
      gcloud sql users delete "$db_user" --host=% --instance="$db_srv" -q
    	# delete all instances with wordpress in the name
      VMS_TO_DELETE=$(gcloud compute instances list --filter="name~wordpress" --format="value(name)")
      if [[ -n "$VMS_TO_DELETE" ]]; then
        for vm in $VMS_TO_DELETE; do
          echo "Deleting VM: $vm"
          gcloud compute instances delete "$vm" -q
        done
      fi
    exit 1
  fi
}

function check_dependencies() {
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

VM_NAME="wordpress-$(date +%s)"
TARGET_TAGS=http-server
MACHINE_TYPE="e2-small"
DOCKER_IMAGE="seifsabry/wordpress_mysql"
TEMP_DIR="/tmp/w3"
WORDPRESS_EXTRACT="/tmp/w3/html"

db_srv=$1
db_version=MYSQL_8_0_26
db_user=wordpress
db_name=wordpress

db_ip=$(gcloud sql instances describe "${db_srv}" --format='value(ipAddresses.ipAddress)')
IP_ADDRESS="$(curl -4 icanhazip.com --silent)/32"
msg="
-----------------------------------------
Run the installation script as follows:
    $(basename "$0") <DB_INSTANCE> [-d|--delete]
    $(basename "$0") -h|--help

Where:
<DB_INSTANCE> : the name of the db server
------------------------------------------"

if [[ $# -eq 0 ]]; then
    echo "$msg"
    exit 1
elif [[ $# -eq 1 ]]; then
  check_help "$1"
elif [ $# -eq 2 ]; then
  check_delete "$1" "$2" "$db_user" "$db_name" "$db_srv"
else
  echo "Too many arguments"
  echo "$msg"
  exit 1
fi

function create_vm() {
  gcloud compute instances create-with-container "${VM_NAME}" \
    --machine-type=${MACHINE_TYPE} \
    --tags="${TARGET_TAGS}" \
    --container-image="${DOCKER_IMAGE}" \
    --container-privileged
}

function clear_and_recreate_dir() {
  rm -rf "${WORDPRESS_EXTRACT}"
  mkdir -p "${WORDPRESS_EXTRACT}"
}

function get_wordpress() {
  echo "Downloading wordpress..."
  curl https://wordpress.org/latest.tar.gz --silent | tar -zx -C "${WORDPRESS_EXTRACT}"
  mv "${WORDPRESS_EXTRACT}"/wordpress/* "${WORDPRESS_EXTRACT}"
  echo "Downloaded wordpress"
}

function get_parameters() {
  # Get password for wordpress db user
  read -s -r -p "Wordpress db password: " wordpresspass
  echo ""
  # Get password for root user
  read -s -r -p "DB root password: " rootpass
  echo ""
}

function compress_wordpress() {
  echo "Compressing wordpress..."
  cd "${TEMP_DIR}" || exit
  tar -czf ./wordpress.tar.gz ./html
  echo "Compressed wordpress"
}

function set_wordpress_config(){
  cp "${WORDPRESS_EXTRACT}"/wp-config-sample.php "${WORDPRESS_EXTRACT}"/wp-config.php
  sed -i'.bak' s/database_name_here/${db_name}/g "${WORDPRESS_EXTRACT}"/wp-config.php
  sed -i'.bak' s/username_here/${db_user}/g "${WORDPRESS_EXTRACT}"/wp-config.php
  sed -i'.bak' s/password_here/"${wordpresspass}"/g "${WORDPRESS_EXTRACT}"/wp-config.php
  sed -i'.bak' s/localhost/"${db_ip}"/g "${WORDPRESS_EXTRACT}"/wp-config.php
  rm "${WORDPRESS_EXTRACT}"/wp-config.php.bak
}

function f_checkdbinst {
    if [[ -z $(gcloud sql instances describe "${db_srv}" 2>/dev/null) ]]; then
        echo "The database server does not exist. Did you type it correctly?"
        echo "Otherwise you may need to create it."
        exit 200
    fi
    db_inst_version=$(gcloud sql instances describe "${db_srv}" \
        --format='value(databaseVersion)')
    if ! [[ $db_version = "${db_inst_version}" ]]; then
        echo "----------------------------------------"
        echo "The database version is not correct"
        echo -e "Required\t: ${db_version}"
        echo -e "Installed\t: ${db_inst_version}"
        echo "----------------------------------------"
        exit 100
    fi
}

function f_authnw {
    # Get the list of current authnw
    current_authnw=$(gcloud sql instances describe "${db_srv}" \
        --format='value(settings.ipConfiguration.authorizedNetworks[].value)' \
        |tr ";" ",")

    # Get the IP of the VM
    vm_ip=$(gcloud compute instances describe "${VM_NAME}" \
        --format='value(networkInterfaces[0].accessConfigs[0].natIP)')
    if [[ -z ${current_authnw} || ${current_authnw} = "0.0.0.0/0" ]]; then
        gcloud sql instances patch "${db_srv}" --authorized-networks="${vm_ip},${IP_ADDRESS}" -q
    else
        current_authnw+=,${vm_ip}
        gcloud sql instances patch "${db_srv}" \
            --authorized-networks="${current_authnw}","${IP_ADDRESS}" -q
    fi
}

function create_dockerfile() {
    cd "${TEMP_DIR}" || exit
    echo "
FROM ubuntu:latest
LABEL authors=\"seifeldinismail\"
ENV TZ=Europe/Brussels
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 php php-mysql \
    && rm -rf /var/www/html/*
ADD ./wordpress.tar.gz /var/www
ENTRYPOINT [\"/usr/sbin/apache2ctl\", \"-D\", \"FOREGROUND\"]
EXPOSE 80
" > "Dockerfile"
    docker buildx build --push --platform linux/amd64,linux/arm64 -t ${DOCKER_IMAGE} .
}

# This was necessary only for the first time to publish to my dockerhub
function setup_docker_file() {
  get_wordpress
  set_wordpress_config
  compress_wordpress
  create_dockerfile
}

function create_db_user_if_not_exists() {
  echo "Setting up DB and user."
  echo "Database Ip: ${db_ip}"
  mysql --host "${db_ip}" --user=root --password="${rootpass}" <<EOF
  DROP DATABASE IF EXISTS ${db_name};
  CREATE DATABASE ${db_name};
  DROP USER IF EXISTS ${db_user};
  CREATE USER ${db_user} IDENTIFIED BY '${wordpresspass}';
  GRANT ALL PRIVILEGES ON ${db_name}.* to ${db_user};
  FLUSH PRIVILEGES;
EOF
}

check_dependencies "gcloud" "mysql" "docker"
f_checkdbinst
clear_and_recreate_dir
get_parameters
create_db_user_if_not_exists
# This was necessary only for the first time to publish to my dockerhub
#setup_docker_file
create_vm
f_authnw

echo "----------------------------------------"
echo "The wordpress installation is complete."
echo "visit http://${vm_ip}/wp-admin/install.php to access your site."
