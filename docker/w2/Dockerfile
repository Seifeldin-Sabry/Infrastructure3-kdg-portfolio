FROM alpine
LABEL authors="seifeldinismail"

# add the application 'irssi' with the command `apk add irssi`
RUN apk add irssi
ENV USER seifsabry
# Create a new user in the image to run this application. Use 'adduser', no password required. make sure /home/seifsabry is created
RUN adduser -D $USER

# The configuration file the you find in the annex needs to be copied to /home/seifKdgAcs/.irssi/
COPY ./config /home/$USER/.irssi/config

RUN chown -R $USER /home/$USER/.irssi
USER seifsabry
WORKDIR /home/$USER
# default option when running the container should run --help
ENTRYPOINT ["irssi"]
CMD ["--help"]




# the name of repository/tag seifsabry/seifrepo:v1
# command to run: `docker run -it --rm seifsabry/seifrepo:v1`