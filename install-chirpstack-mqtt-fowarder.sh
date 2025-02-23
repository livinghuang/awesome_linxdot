#!/bin/sh

# Linxdot opensource: 
# Main purpose: to install and start lora_pkd_fwd in serves after background;
# By Louis Chuang 2024-04-04.

service_file="/etc/init.d/linxdot-chirpstack-mqtt-fowarder"

if [ ! -f "$service_file" ]; then

    # the service file is not exist!
   echo "-------- 2. the service is not installed. To create it."
   echo "#!/bin/sh /etc/rc.common
    
    START=99
    USE_PROCD=9001

   start_service() {

        logger -t "starting chirpstack-mqtt-fowarder service!...."
        procd_open_instance
        procd_set_param command "/etc/awesome_linxdot/run_chirpstack_mqtt_fowarder.sh" 
        procd_set_param respawn
        procd_close_instance

        logger -t "chirpstack-mqtt-fowarder service started!"
    }

   " > $service_file

    chmod +x $service_file
    $service_file enable

    $service_file start

fi