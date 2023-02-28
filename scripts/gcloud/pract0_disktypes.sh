#!/bin/bash

#The command ‘gcloud compute disk-types list’ returns a list of all possible disk types that you can assign to your instance (in your local terminal).
 #
 #If you execute the command in the Google cloud shell and you want a comparable output, use the following command:
 #
 #gcloud compute disk-types list --format=”csv[separator=’ ‘](NAME,ZONE,VALID_DISK_SIZES)”

 #Write a script that expects 2 strings as input parameters. The first parameter is the type of disk (standard, ssd, balanced). The second parameter is the region in which the Google data center is located.
   #
   #The script displays which disks of a certain disk type are available in a certain region. The displayed list shows the disks of the required disk type, the data center location and the minimum disk size.
   #
   #If a non-existing continent or disk has been chosen, then the error message ‘FOUND NOTHING’ should be displayed, with ‘NOTHING’ in red colors. Also display some help text.
   #
   #The script should not be run as root.
   #
   #Apply Bash best practices.


# check if running as root
if [ "$EUID" -eq 0 ]
  then echo "Please do not run as root"
  exit 1
fi

# check if --help is supplied
if [ "$1" = "--help" ]; then
  echo -e "Usage: supply disk type and region, eg: 'pract0_disktypes.sh standard europe-west1'"
  echo -e "Disk types: standard, ssd, balanced"
  echo -e "enter a valid region, eg: 'europe-west1' to find the regions use 'gcloud compute regions list'"
  echo -e "Purpose: displays the disks of a certain disk type in a certain region"
  exit 1
fi

# check if 2 parameters are supplied
if [ "$#" -ne 2 ]; then
  echo -e "Usage: supply disk type and region, eg: 'pract0_disktypes.sh standard europe-west1'"
  echo -e "Disk types: standard, ssd, balanced"
  echo -e "enter a valid region, eg: 'europe-west1' to find the regions use 'gcloud compute regions list'"
  echo -e "Purpose: displays the disks of a certain disk type in a certain region"
  exit 1
fi

# check if valid disk type is supplied using regex
regex="^(standard|ssd|balanced)$"
if ! [[ $1 =~ $regex ]]; then
  echo e- "FOUND NOTHING" | sed -e 's/NOTHING/\\033[0;31m&\\033[0m/'
  echo -e "Disk types: standard, ssd, balanced"
  echo -e "enter a valid region, eg: 'europe-west1' to find the regions use 'gcloud compute regions list'"
  echo -e "Purpose: displays the disks of a certain disk type in a certain region"
  exit 1
fi

# check if valid region is supplied
if ! gcloud compute regions describe "$2" > /dev/null; then
  echo -e "\033[0;31mFOUND NOTHING\033[0m"
  exit 1
fi
gcloud compute disk-types list | grep $1 | grep $2 | awk '{print FOUND $1, $2, $3}'


