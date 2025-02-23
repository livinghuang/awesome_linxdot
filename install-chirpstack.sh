#!/bin/sh

# Linxdot opensource: 
# Main purpose: to install chirpstack service in the LD1001/LD1002 hotspot.
# By Living Huang 2025-02-23.

#step 1 : check the repo of chirpstack is available and install!

system_dir="/opt/awesome_linxdot/chirpstack-software"

echo "step 1: check the chirpstack to see if it is started"

#step 1 : check the service if it is available.

service_file="/etc/init.d/linxdot-chripstack-service"

if [ ! -f "$service_file" ]; then

    # the service file is not exist!
   echo "-------- 2. the service is not installed. To create it."
   echo "#!/bin/sh /etc/rc.common
    START=99

    start() {

        logger -t "try to start chirpstack service...."
        cd $system_dir/chirpstack-docker
        docker-compose up -d --remove-orphans
        logger -t "call chirpstack 'docker-compose up -d'  is ok, please check the docker compose"
    }

    stop(){
        :
    } 
   " > $service_file

    chmod +x $service_file
    $service_file enable

    $service_file start

fi

echo "step 2: completed installed and running the service!"

