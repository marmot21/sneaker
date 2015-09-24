#!/bin/bash

## in /usr/lib/check_mk_agent/local

amb_temp="/sys/bus/w1/devices/28-04146f6d29ff/w1_slave"
whide_temp="/sys/bus/w1/devices/28-04146f5a3eff/w1_slave"

tempRAW=`getTemp $amb_temp`
tempAFP=`bc -l <<< "$tempRAW / 1000" | cut -c1-6`

tempRAW=`getTemp $whide_temp`
tempWHFP=`bc -l <<< "$tempRAW / 1000" | cut -c1-6`

echo "P Other_temps abmient=$tempAFP|warm_hide=$tempWHFP"

