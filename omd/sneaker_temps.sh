#!/bin/bash

## in /usr/lib/check_mk_agent/local

whm_temp="/sys/bus/w1/devices/28-04146f5905ff/w1_slave"

tempFP=`bc -l <<< "35864 / 1000" | cut -c1-6`
echo 0 temp_test temp=$tempFP OK - temp 15

