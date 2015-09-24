#!/bin/bash

#aim is to keep temp between 32 and 35 C on surface
MAX_TEMP=360
MIN_TEMP=335
ALERT_LOW=300 # 30.0 C
ALERT_HIGH=400 # 40.0 C
LOG=/home/pi/temp.log
PROBE_PATH="/sys/bus/w1/devices/"
NON=1
NOFF=0

PROBE_HEATMAT=$PROBE_PATH"28-04146f5905ff/w1_slave"
PROBE_AMBIENT=$PROBE_PATH"28-04146f6d29ff/w1_slave"
PROBE_WRMHIDE=$PROBE_PATH"28-04146f5a3eff/w1_slave"
PROBE_COOLHEAT=$PROBE_PATH"28-04146f755eff/w1_slave"
GPIO_HM=17
GPIO_CHM=18



# Get the temp from the tempature file
#function getTemp {
#	echo `cat $1 | grep "t=" | sed "s/.*t=\([0-9][0-9]\)/\1/"`
#}

# Get the temp and return it as a floating point number
function getTempFP {
	local tempRAW=`getTemp $1`
	echo `bc -l <<< "$tempRAW / 1000" | cut -c1-6`
}

function setHM {
# $1 HM temp
# $2 HM Target max
# $3 HM Target Min
# $4 GPIO Pin
# $5 GPIO N-ON 0/1
# $6 HM tempFP - floating point temp
# $7 HR Name

## If we are normally off
if [ "$5" = $NOFF ]
then
	local PIN_OFF=1
	local PIN_ON=0
else
	local PIN_OFF=0
	local PIN_ON=1
fi

if [ $1 -gt $2 ] && [ `gpio get $4` -eq $5 ]
then
	echo [`date '+%c'`]: Event: Turning off $7 heatmat, HMtemp: $6 >> $LOG
	gpio mode $4 out
	gpio write $4 $PIN_OFF #turn off

elif [ $1 -lt $3 ] && [ `gpio get $4` -ne $5 ]
then
	echo [`date '+%c'`]: Event: Turning on $7 heatmat, HMtemp: $6 >> $LOG
	
	gpio mode $4 out
	gpio write $4 $PIN_ON #turn on
fi
}

#load gpio stuff
source gpio
gpio mode $GPIO_HM out
gpio mode $GPIO_CHM out

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

echo $tempRAW $tempFP $tempHM

# Other tank temps
tempAmbFP=$(getTempFP $PROBE_AMBIENT)
tempWrmHideFP=$(getTempFP $PROBE_WRMHIDE)
tempCoolHMFP=$(getTempFP $PROBE_COOLHEAT)

tempCHM=$(expr $(getTemp $PROBE_COOLHEAT) / 100)

setHM $tempHM $MAX_TEMP $MIN_TEMP $GPIO_HM $NOFF $tempFP "Warm"
setHM $tempCHM 270 240 18 $NON $tempCoolHMFP "Cool"

if [ `gpio get $GPIO_HM` -eq 0 ]
then 
	MAT_STATUS=ON
else
	MAT_STATUS=OFF
fi	
	
echo "[`date '+%c'`] Info: HeatMat $tempFP, heat $MAT_STATUS; WarmHide: $tempWrmHideFP, Ambient: $tempAmbFP", CoolHM: $tempCoolHMFP >> $LOG

# Alert if out of range
if [ $tempHM -gt $ALERT_HIGH ] || [ $tempHM -lt $ALERT_LOW ]
then
	echo [`date '+%c'`]: CRITICAL: "Temp out of range: $tempFP" >> $LOG
	echo "Temp out of range: $tempFP, last log:
`tail $LOG`" | mail -aFrom:pi@marmotic.com -s "Subject: Sneaker - Critical" marmot.daniel@gmail.com &
fi

exit 0

