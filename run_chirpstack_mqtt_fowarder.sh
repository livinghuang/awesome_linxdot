#!/bin/sh

# Linxdot opensource: 
# Main purpose: to call the lora_pkt_fwd runtime in backgrond;
# By Louis Chuang 2024-04-04.

echo "chirpstack-mqtt-forwarder start!!"
cd /etc/linxdot-opensource/chirpstack-software/chirpstack-mqtt-forwarder-binary

 while [ true ]; do

     ./chirpstack-mqtt-forwarder -c ./chirpstack-mqtt-forwarder.toml | logger -t chirpstack-mqtt-forwarder

 done

exit 0