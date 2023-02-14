#!/bin/bash

#Function:  Convert IP addresses to names
#Name:      nslookup.sh
#Required:  nslookup

#The script reads the lines from ips.txt, one by one.
#
#
#The script uses the function fun_nslookup(). This function takes as first argument an IP address and returns the name found by the command nslookup $ip.
#Use a for loop with a regex group to extract the name from the output.
#
#
#The script displays the names on the terminal.
IFS='
'

# check if --help is supplied
if [ "$1" = "--help" ]; then
  echo -e "Usage: supply file eg: 'nslookup.sh <file>'"
  echo -e "Note: file must be supplied"
  echo -e "Converts IP addresses to names"
  exit 1
fi

regex="(name = )(.*)\."

fun_nslookup()
{
  result=$(nslookup $1)
  [[ $result =~ $regex ]]
  name="${BASH_REMATCH[2]}"
  echo "The name of IP address $1 is $name"
}

for line in $(cat ips.txt); do
  fun_nslookup "$line"
done

unset IFS