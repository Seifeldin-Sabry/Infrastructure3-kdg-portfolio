#!/bin/bash

#Function: countdown: counts down from 60 or param passed to 0
#Name: countdown.sh



# Usage --help
if [ "$1" = "--help" ]; then
  echo -e "Usage: supply duration eg: 'countdown.sh <duration in seconds>' \ndefault set to 60s"
  exit 1
fi

duration=${1:-"60"}

#check if input passed is a number
if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
  echo "Please supply a number or use --help"
  exit 2
fi



countdown()
{
  tput civis # hide cursor
  for (( i = "${duration}"; i >= 0; i-- )); do
    echo -ne "\r$i" # -n: no newline, -e: interpret backslash escapes
    sleep 1
  done
  tput cnorm # show cursor
  echo
}

countdown