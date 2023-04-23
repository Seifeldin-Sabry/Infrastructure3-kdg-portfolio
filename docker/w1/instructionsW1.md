### How to run docker image

##### install the docker image: ubuntu:22.04
1. `docker run -it --name seifcontainer ubuntu:22.04`
<br>
you should be inside the container's shell now
2. `apt-get update && apt-get install -y apache2`
3. `echo "Hey, this is your captain speaking, CAPTAIN USOPP!" > /var/www/html/index.html`
4. `exit`

##### commit the container
1. `docker commit \
   --author "Seifeldin Sabry kdg" \
   --message "my first image" \
   seifcontainer myacs/myfirstimage:acs`

##### checking the image exists
1. `docker images | grep myfirstimage`

##### checking the author and message, and the tag
1. `docker inspect myacs/myfirstimage:acs | grep -i author`
2. `docker inspect myacs/myfirstimage:acs | grep -i message`
3. `docker inspect myacs/myfirstimage:acs | grep -i acs` # should be under "RepoTags"

##### run the image
1. `docker run -it --name seifcontainer2 myacs/myfirstimage:acs`

##### check apache2 exists and html file is overwritten
1. `which apache2` "should show a path if exists"
2. `cat /var/www/html/index.html` "should show the content of the file which is "Hey, this is your captain speaking, CAPTAIN USOPP!"