#!/bin/sh

# Linxdot opensource: 
# Main purpose: to install and start lora_pkd_fwd in serves after background;
# By Louis Chuang 2024-04-04.

region="as923"

service_file="/etc/init.d/chirpstack-gateway-mesh"

if [ ! -f "$service_file" ]; then

    # the service file is not exist!
   echo "-------- 2. the service is not installed. To create it."
   echo "#!/bin/sh /etc/rc.common
    
    START=99
    USE_PROCD=9888

    thisRegion=$region

   start_service() {

        logger -t "starting chirpstack-gateway-mesh service!...."
        procd_open_instance
        procd_set_param command "/opt/awesome_linxdot/run_chirpstack-gateway-mesh.sh" \$thisRegion
        procd_set_param respawn
        procd_close_instance

        logger -t "chirpstack-gateway-mesh started!"
    }

   " > $service_file

    chmod +x $service_file
    $service_file enable

    $service_file start

fi