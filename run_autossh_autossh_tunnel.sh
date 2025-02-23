#!/bin/sh

# Linxdot opensource: 
# Main purpose: to call the lora_pkt_fwd runtime in backgrond;
# By Louis Chuang 2024-04-04.

sleep 20

 while [ true ]; do

      autossh -M 0 -N -R 0.0.0.0:30900:localhost:22 living-border1@220.135.87.247 -p 38022 | logger -t autossh

 done

exit 0