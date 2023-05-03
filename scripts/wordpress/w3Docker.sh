#!/bin/bash

#------------------------------------------------------------------------------
#- Name         : pract4.3-wordpress.sh
#- Date         : 2023-04-27 10:36:09
#- Author       : A. Mini
#- Alias        : -
#- Commit       : wordpress environment on gcloud
#- Descr        : wordpress environment on gcloud
#- Usage        : pract4.3-wordpress.sh <DB_INSTANCE>
#------------------------------------------------------------------------------

function checkHelp() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << EOF
    Description: This script makes a VM in gcloud with a docker container and hosts a wordpress site.
    Usage:       $(basename "$0") <DB_INSTANCE>
    -            $(basename "$0") -h|--help
EOF
    exit 1
  fi
}

db_srv=$1
db_version=MYSQL_8_0_26
db_ip=$(gcloud sql instances describe "${db_srv}" --format='value(ipAddresses.ipAddress)')
frontend=wordpress-fe$(date +%s)
imgproj=ubuntu-os-cloud
imgfam=ubuntu-2204-lts
db_user=wordpress
db_name=wordpress
IP_ADDRESS="$(curl -4 icanhazip.com --silent)"
tags=http-server
msg="
-----------------------------------------
Run the installation script as follows:
    $(basename "$0") <DB_INSTANCE>

Where:
<DB_INSTANCE> : the name of the db server
------------------------------------------"

[ $# -ne 1 ] && { echo "$msg"; exit 1; }

# Function: check if mysql db instance exists and it is the correct version;
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

# Function: fix authorized-networks for access to the db server
function f_authnw {
    # Get the list of current authnw
    current_authnw=$(gcloud sql instances describe "${db_srv}" \
        --format='value(settings.ipConfiguration.authorizedNetworks[].value)' \
        |tr ";" ",")

    # Get the IP of the VM
    vm_ip=$(gcloud compute instances describe "${frontend}" \
        --format='value(networkInterfaces[0].accessConfigs[0].natIP)')
    if [[ -z ${current_authnw} || ${current_authnw} = "0.0.0.0/0" ]]; then
        gcloud sql instances patch "${db_srv}" --authorized-networks="${vm_ip}" -q
    else
        current_authnw+=,${vm_ip}
        gcloud sql instances patch "${db_srv}" \
            --authorized-networks="${current_authnw}","${IP_ADDRESS}" -q
    fi
}

# Function create frontend vm for wordpress site
function f_create_frontend {
    echo -e "\nCreating Wordpress Frontend"
    gcloud compute instances create "${frontend}" \
        --image-project=${imgproj} \
        --image-family=${imgfam} \
        --tags=${tags} \
        --metadata startup-script="#!/bin/bash
            apt update && apt install -y apache2 php php-mysql
            rm /var/www/html/index.html
            curl https://wordpress.org/latest.tar.gz | tar -zx -C /var/tmp
            cp -R /var/tmp/wordpress/* /var/www/html
            cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
            sed -i s/database_name_here/${db_name}/g /var/www/html/wp-config.php
            sed -i s/username_here/${db_user}/g /var/www/html/wp-config.php
            sed -i s/password_here/${wordpresspass}/g /var/www/html/wp-config.php
            sed -i s/localhost/${db_ip}/g /var/www/html/wp-config.php"
}

# MAIN
# Check if database server exists:
f_checkdbinst

# Check if frontend VM already exists; if it does, exit.
if [[ -n $(gcloud compute instances describe "${frontend}" 2> /dev/null) ]]; then
    echo "${frontend} already exists; exiting script.."
    exit 101
else
    # Get password for wordpress db user
    read -s -r -p "Wordpress db password: " wordpresspass
    echo ""
    # Get password for root user
    read -s -r -p "DB root password: " rootpass
    echo ""
    # Create the frontend
    f_create_frontend
fi

# Get the frontend IP
vm_ip=$(gcloud compute instances describe "${frontend}" \
    --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

# update authnw + vm_ip
f_authnw

# Check if mysql-client is installed, otherwise exit
# Create database and database user with mysql-client app
# (WHY?: `gcloud sql users create` does not grant sufficient privileges)
if ! [[ $(which mysql) ]]; then
  echo "mysql-client is not installed."
  exit 1
fi
    # Check with gcloud if Wordpress db already exists
if (gcloud sql databases list --instance="${db_srv}" \
        --format='value(name)' | grep -q "${db_name}") && \
        (gcloud sql users list --instance="${db_srv}" | grep -q "${db_user}"); then
  echo "Wordpress db and user already exist. Skipping.."
else
  echo "Setting up DB and user."
  mysql --host "${db_ip}" --user=root --password="${rootpass}" <<EOF
  DROP DATABASE IF EXISTS ${db_name};
  CREATE DATABASE ${db_name};
  DROP USER IF EXISTS ${db_user};
  CREATE USER ${db_user} IDENTIFIED BY '${wordpresspass}';
  GRANT ALL PRIVILEGES ON ${db_name}.* to ${db_user};
  FLUSH PRIVILEGES;
EOF
fi

echo "-----------------------------------------------"
echo "Installation should be completed."
echo "Wait a minute or two for the dust to settle."
echo "Finish the installation by browsing to:"
echo "http://${vm_ip}/wp-admin/install.php"
echo "-----------------------------------------------"
