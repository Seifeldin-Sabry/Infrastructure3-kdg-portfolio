#!/bin/bash
#Function:   benchmarking test for apache webserver
#Name:       apachetest.sh
#Reference:  man ab
#            man curl
#Required:   apache2, apache2-utils, curl
#
#If necessary, start the apache webserver with the following command:
#
#sudo systemctl start apache
#
#The script has the following functions:
#
#Checks if the programs ‘ab’ (apache benchmark) and ‘curl’ are installed. If they are not installed, stop with exit code 1 and the following message:
#“The programs ab/curl are required. Install them with ‘sudo apt install apache2-utils’ and ‘sudo apt install curl’.”
#
#Check if the user has supplied a URL. If this is not the case, use ‘127.0.0.1’ as the url.
#
#
#Check with ‘curl’ if the supplied url is reachable. If not, return the error message “The url is not reachable.” and stop with exit code 2.
#
#
#Perform the benchmark to test the web server:
#ab -n 100 -kc 10 ${url}
#Note: the url must end with a slash for ‘ab’.

# to check if running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

# check if ab and curl are installed
if ! [ -x "$(command -v ab)" ] || ! [ -x "$(command -v curl)" ]; then
  echo "The programs ab/curl are required. Install them with ‘sudo apt install apache2-utils’ and ‘sudo apt install curl’." >&2
  exit 1
fi

# check if url is supplied
url=${1:-"127.0.0.1"}

# check if url is reachable
if ! curl -s --head  --request GET "${url}" | grep "200 OK" > /dev/null; then
  echo "The url is not reachable."
  exit 2
fi

ab -n 100 -kc 10 "${url}"


