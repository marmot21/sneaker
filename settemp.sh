#!/bin/bash

#aim is to keep temp between 32 and 35 C on surface
MAX_TEMP=360
MIN_TEMP=338
ALERT_LOW=300 # 30.0 C
ALERT_HIGH=400 # 40.0 C
LOG=/home/pi/temp.log
PROBE_PATH="/sys/bus/w1/devices/"

PROBE_HEATMAT=$PROBE_PATH"28-04146f7399ff/w1_slave"
PROBE_AMBIENT=$PROBE_PATH"28-04146f6d29ff/w1_slave"
PROBE_WRMHIDE=$PROBE_PATH"28-04146f5a3eff/w1_slave"
GPIO_HM=17

# Get the temp from the tempature file
function getTemp {
	echo `cat $1 | grep "t=" | sed "s/.*t=\([0-9][0-9]\)/\1/"`
}

# Get the temp and return it as a floating point number
function getTempFP {
	local tempRAW=`getTemp $1`
	echo `bc -l <<< "$tempRAW / 1000" | cut -c1-6`
}

#load gpio stuff
source gpio
gpio mode $GPIO_HM out

#check probe is active
if [ ! -f $PROBE_HEATMAT ]
then
	echo [`date '+%c'`]: CRITICAL: "Can't find heatmmat temp probe!!" >> $LOG
	
	echo "Temp probe missing, last log:
`tail $LOG`" | mail -aFrom:pi@marmotic.com -s "Sneaker - Critical" marmot.daniel@gmail.com &

	# Failback toggle heat mat
	if [ `gpio get $GPIO_HM` -eq 0 ]
	then 
		gpio mode $GPIO_HM out
		gpio write $GPIO_HM 1
	else
		gpio mode $GPIO_HM out
		gpio write $GPIO_HM 0
	fi	
exit 1
fi

# Heatmat temp
tempRAW=$(getTemp $PROBE_HEATMAT)
tempFP=`bc -l <<< "$tempRAW / 1000" | cut -c1-6`
tempHM=`expr $tempRAW / 100`

# Other tank temps
tempAmbFP=$(getTempFP $PROBE_AMBIENT)
tempWrmHideFP=`bc -l <<< "$(getTemp $PROBE_WRMHIDE) / 1000" | cut -c1-6`

if [ $tempHM -gt $MAX_TEMP ] && [ `gpio get $GPIO_HM` -eq 0 ]
then
	echo [`date '+%c'`]: Event: Turning off heatmat, HMtemp: $tempFP >> $LOG
	gpio mode $GPIO_HM out
	gpio write $GPIO_HM 1 #turn off

else if [ $tempHM -lt $MIN_TEMP ] && [ `gpio get $GPIO_HM` -eq 1 ]
		then
		echo [`date '+%c'`]: Event: Turning on heatmat, HMtemp: $tempFP >> $LOG
		gpio mode $GPIO_HM out
		gpio write $GPIO_HM 0 #turn on

	else
		if [ `gpio get $GPIO_HM` -eq 0 ]
		then 
			MAT_STATUS=ON
		else
			MAT_STATUS=OFF
		fi
		echo "[`date '+%c'`] Info: HeatMat $tempFP, heat $MAT_STATUS; WarmHide: $tempWrmHideFP, Ambient: $tempAmbFP" >> $LOG
	fi
fi


# Alert if out of range
if [ $tempHM -gt $ALERT_HIGH ] || [ $tempHM -lt $ALERT_LOW ]
then
	echo [`date '+%c'`]: CRITICAL: "Temp out of range: $tempFP" >> $LOG
	echo "Temp out of range: $tempFP, last log:
`tail $LOG`" | mail -aFrom:pi@marmotic.com -s "Subject: Sneaker - Critical" marmot.daniel@gmail.com &
fi

exit 0

