#!/bin/bash

## in /usr/lib/check_mk_agent/local

whm_temp="/sys/bus/w1/devices/28-04146f5905ff/w1_slave"
chm_temp="/sys/bus/w1/devices/28-04146f755eff/w1_slave"

tempRAW=`getTemp $whm_temp`
tempWFP=`bc -l <<< "$tempRAW / 1000" | cut -c1-6`

tempRAW=`getTemp $chm_temp`
tempCFP=`bc -l <<< "$tempRAW / 1000" | cut -c1-6`

echo "P HeatMat_temps warm_mat=$tempWFP;31:37;28:39|cool_mat=$tempCFP;21:28;18:35"

