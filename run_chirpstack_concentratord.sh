#!/bin/sh

# Linxdot opensource: 
# Main purpose: to call the lora_pkt_fwd runtime in backgrond;
# By Louis Chuang 2024-04-04.

if [ -z "$1" ]
then

      echo "the parameter is empty use default"
      region="as923"
       echo "the regions is $region"
else
      echo "the regions is $1"
      region=$1
fi

cd /etc/linxdot-opensource/chirpstack-software/chirpstack-concentratord-binary

 while [ true ]; do

      ./chirpstack-concentratord-sx1302 -c /etc/linxdot-opensource/chirpstack-software/chirpstack-concentratord-binary/config/concentratord.toml -c /etc/linxdot-opensource/chirpstack-software/chirpstack-concentratord-binary/config/channels_$region.toml -c /etc/linxdot-opensource/chirpstack-software/chirpstack-concentratord-binary/config/region_$region.toml | logger -t chirpstack-concentratord

 done

exit 0