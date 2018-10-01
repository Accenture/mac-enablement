#!/bin/sh

<<ABOUT_THIS_SCRIPT
----------------------------------------------------------------------------
 Symantec Health Check v1.0 
 Created 18 Aug 2018 by Christopher Kemp for Accenture
 
 Written for use with Symantec Endpoint Protection v14. 
 This script performs a check of 8 elements of local health, scores them, 
 and then converts the result into a binary string: 1 is a pass, 0 is a fail. 
 The results can be read left to right, indicating what condition has failed:

 SEP 14 is installed
 Last Scan is less than 14 days ago
 NTP Definitions are newer than 14 days
 AV Definitions are newer than 14 days
 IPS kext loaded
 NFS kext loaded
 Internet Security kext loaded
 SyLink file exists

 so a score of 11111111 = a presumably healthy client
 
 Note that this is strictly a local check - it does not validate communication
 with a SEPM server. If you figure that one out please let me know! :)
----------------------------------------------------------------------------
ABOUT_THIS_SCRIPT

# Extension Attribute definitions for posting to jamf server
# DO NOT CHANGE THIS PARAMETERS!
jssUser="FILL IN THE BLANK"
jssPassword="FILL IN THE BLANK"
jssUrl="FILL IN THE BLANK"
EXTATTRID="FILL IN THE BLANK" # ID of the Extension Attribute to update
EXTATTRNAME="FILL IN THE BLANK" # Name of the Extension Attribute to update
host=`system_profiler SPHardwareDataType | awk '/UUID/ { print $3; }'`

## Declarations of integer values
declare -i scanWarn
declare -i scanNC
declare -i hc1
declare -i hc2
declare -i hc4
declare -i hc8
declare -i hc16
declare -i hc32
declare -i hc64
declare -i hc128

# Setting a few variables:
# Log results of various Health Checks here:
shcLog=/tmp/SEP14_Health_Check.txt

# Get current date and time in seconds for aging calculations
epochDate=`date -j +%s`

# Location of SymAVLog database for getting Last Scan Date
sq3Dir='/Library/Application Support/Symantec/Silo/NFM/SymUIAgent/Logs'

# Initialize the status variable for evaluation in jamf pro
shcStat=0

# number of days for scanWarn (yellow), scanNC (red, non-compliance for SEP scan) 
scanWarn=7
scanNC=14

required_vars=(SyLink kxt1 kxt2 kxt3 symDate lastAVDef lastNTPDef)

# BEGIN
startTime=`date`
echo "Symantec Health Check, $startTime"  > $shcLog
echo ""  >> $shcLog

# Health Check 0, presence of Symantec Endpoint Protection.
appIsPresent=`ls /Applications/Symantec\ Solutions/ | grep Symantec\ Endpoint\ Protection.app`
if [ -n "$appIsPresent" ]; then
# RAISE THIS VALUE if additional checks are added!
	hc0=128
else
	echo "Symantec Application not found, exiting..." >> $shcLog
	exit 1
fi

# Health Check 1, presence of SyLink file
SyLink=`ls /Library/Application\ Support/Symantec/SMC/ | grep SyLink.xml`

if [ -n "$SyLink" ]; then
	SyLinkStat="OK"
	hc1=1
else
	SyLinkStat="Not Found"
	hc1=0
fi

# verify loaded kexts
kxt1=`kextstat -l | grep symantec.internetSecurity | awk '{print $6}'`
if [ -n "$kxt1" ]; then
  Kext1Stat="OK"
	hc2=2
else
  Kext1Stat="Not Loaded"
	hc2=0
fi

kxt2=`kextstat -l | grep symantec.nfm | awk '{print $6}'`
if [ -n "$kxt2" ]; then
  Kext2Stat="OK"
	hc4=4
else
  Kext2Stat="Not Loaded"
	hc4=0
fi

kxt3=`kextstat -l | grep symantec.ips | awk '{print $6}'`
if [ -n "$kxt3" ]; then
  Kext3Stat="OK"
	hc8=8
else
  Kext3Stat="Not Loaded"
	hc8=0
fi

# Check dates of SEP AV and NTP definitions. Definitions should be within (X) days old.
# Get current date and time in seconds
epochDate=`date -j +%s`

# get date of AV definitions
lastAVDef=`/usr/bin/grep CurDefs /Library/Application\ Support/Symantec/Silo/NFM/Definitions/virusdefs/definfo.dat  | /usr/bin/cut -c 9-16`
# Convert date to epoch for calculation - we add "0000" to represent hours and minutes
# in order to make the 'date' command happy when converting to epoch (seconds). :)
epochDefAge=`date -j -f '%Y%m%d%H%M' $lastAVDef"0000" +'%s'`

# Do the maths...
avDefAge=`echo "($epochDate-$epochDefAge)/60/60/24" | bc`
if [ -n "$avDefAge" ]; then
	if [ $avDefAge -lt $scanNC ]; then
  	avDefStat="OK"
		hc16=16
	else 
		avDefStat="Out of date"
		hc16=0
	fi
else
	avDefStat="Not Available"
	hc16=0
fi 

# get date of NTP definitions
lastNTPDef=`/usr/bin/grep CurDefs /Library/Application\ Support/Symantec/Silo/NFM/Definitions/symcdata/vulnprotectiondefs/definfo.dat  | /usr/bin/cut -c 9-16`
# Convert date to epoch for calculation - we add "0000" to represent hours and minutes
# in order to make the 'date' command happy when converting to epoch (seconds). :)
epochNtpAge=`date -j -f '%Y%m%d%H%M' $lastNTPDef"0000" +'%s'`

# Do the maths...
ntpDefAge=`echo "($epochDate-$epochNtpAge)/60/60/24" | bc`
if [ -n "$ntpDefAge" ]; then
	if [ $ntpDefAge -lt $scanNC ]; then
	  ntpDefStat="OK"
		hc32=32
	else
		ntpDefStat="Out of date"
		hc32=0
	fi
else
	ntpDefStat="Not Available"
	hc32=0
fi 

# Get Last Scan Date
symDate=`sqlite3 "$sq3Dir"/SymAVLog 'select datetime(timeStamp, "unixepoch", "localtime", "+31 years") dateas_string from LogEntry where terminationCode = 0;' | tail -1 | awk -F"[ ]" '{print $1}'`
epochScanDate=`date -j -f "%Y-%m-%d" $symDate +%s`

## Do the maths...
lastScan=`echo "($epochDate-$epochScanDate)/60/60/24" | bc`
if [ -n "$lastScan" ]; then
	if [ $lastScan -lt $scanNC ]; then
  	scanStat="OK"
		hc64=64
	else
		scanStat="Out of date"
		hc64=0
	fi
else
	echo "missing Last Scan Date..."  >> $shcLog
	hc64=0
fi 

# Add up the score, convert to binary for the check key:
healthScore=`echo "$hc1+$hc2+$hc4+$hc8+$hc16+$hc32+$hc64+$hc0" | bc`
hcBreakdown=`echo "obase=2;$healthScore" | bc`

# Final output. hcBreakdown score can be used to evaluate what components have failed.
## Curl $hcBreakdown into an EA
curl -sku $jssUser:$jssPassword -H "Content-type: application/xml" $jssUrl/JSSResource/computers/udid/$host -d  "<computer><extension_attributes><extension_attribute><id>$EXTATTRID</id><name>$EXTATTRNAME</name><type>String</type><value>$hcBreakdown</value></extension_attribute></extension_attributes></computer>" -X PUT > /dev/null
                                     
if [[ $hcBreakdown = 11111111 ]]; then 
	echo "The Symantec Client appears healthy."
else
	echo "There is a problem with the Symantec client."
fi

exit 0