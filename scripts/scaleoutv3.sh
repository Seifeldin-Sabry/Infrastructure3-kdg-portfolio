#!/bin/bash

# Author: Seifeldin Sabry

# Description: This script creates an instance group from a template and scales it out by a specified number of instances that autoscales
# if passed parameter -r or --resize, it will resize the instance group to the specified number of instances
# if passed parameter -d or --delete, it will delete the instance group

# Usage: ./scaleoutv2.sh [OPTIONS] [PARAMETERS]

# OPTIONS:
# -h, --help              Display these instructions
# -r, --resize <SIZE>     Resize the instance group to the specified number of instances
# -d, --delete            Delete the instance group
# no option               Scale out the instance group by the specified number of instances

VM_NAME="apache-server"
TEMPLATE_NAME="instance-1680099339"
ZONE="europe-west1-b"
SIZE=3
MIN_SIZE=1
MAX_SIZE=10
COOLDOWN_PERIOD=15

# check if --delete or -d flag is passed
if [[ "$1" == "--delete" || "$1" == "-d" ]]; then
  gcloud compute instance-groups managed delete "${VM_NAME}" --quiet
  echo "Instance group deleted"
  exit 0
fi

# check if --resize or -r flag is passed
if [[ "$1" == "--resize" || "$1" == "-r" ]]; then
  # check if the second parameter is passed and is a number between MIN_SIZE and MAX_SIZE
  if [[ "$2" =~ ^[0-9]+$ && "$2" -ge "$MIN_SIZE" && "$2" -le "$MAX_SIZE" ]]; then
    gcloud compute instance-groups managed resize "${VM_NAME}" --size="${2}" --quiet
    echo "Instance group resized to ${2} instances"
    exit 0
  else
    echo "Please specify a number of instances to resize the instance group to between ${MIN_SIZE} and ${MAX_SIZE}"
    exit 1
  fi
fi

# create instance group with autoscaling based on CPU load
gcloud compute instance-groups managed create "${VM_NAME}" \
--size="${SIZE}" \
--base-instance-name="${VM_NAME}" \
--template="${TEMPLATE_NAME}" \
--zone="${ZONE}"

# set autoscaling policy
gcloud compute instance-groups managed set-autoscaling "${VM_NAME}" \
--cool-down-period="${COOLDOWN_PERIOD}" \
--max-num-replicas="${MAX_SIZE}" \
--min-num-replicas="${MIN_SIZE}"
