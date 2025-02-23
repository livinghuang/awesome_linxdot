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

cd /etc/linxdot-opensource/chirpstack-border-gateway/chirpstack-gateway-mesh-binary
#./chirpstack-gateway-mesh -c ./config/chirpstack-gateway-mesh.toml -c ./config/region_$region.toml > /var/log/gateway_mesh.log 2>&1 &

 while [ true ]; do

     ./chirpstack-gateway-mesh -c ./config/chirpstack-gateway-mesh.toml -c ./config/region_$region.toml | logger -t chirpstack-border-gateway-mesh

 done

exit 0