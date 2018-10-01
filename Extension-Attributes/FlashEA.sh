#!/bin/bash

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------
 Flash Player.app Checker v. 1.0 
 Created 18 Aug 2018 by Christopher Kemp for Accenture
 This script will iterate through the Applications folder
 finding all standalone versions of the Adobe Flash Player.app.
 It will version-check all copies that it finds, and if it finds any 
 that are out-of-date then it will flag the machine.
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

## Enter the current version of Flash Player.app
## OR: do this via the API... (tbd)
current_version="30.0.0.134"

# Initialize these variables for use inside of loops
Result1="nil"
Result2="nil"
## Search for Flash Player in Adobe sub-folders, note full path as an array element
IFS=$'\n' read -rd '' -a appArray <<<"$(find /Applications/Adobe* -type d -name "Flash Player.app")"
set -u
## check version numbering for each version in array and test against $current_version
if [ ${#appArray[@]} -eq 0 ]; then
	Result2="Not Found"
else
	for i in "${appArray[@]}"; 
	do 	version=$(defaults read "$i"/Contents/Info.plist CFBundleShortVersionString);
			echo "$version found in $i..." 
				if [ "$version" = "$current_version" ] ;
					then
						Result2="OK"
				else
	#If we find an outdated version flag the machine & exit
					Result2="Flagged"
					break
				fi				
	done
fi

# If nothing in an Adobe sub-folder, check directly in Applications...
if [ -d "/Applications/Flash Player.app" ]; then
	version=$(defaults read "/Applications/Flash Player.app/Contents/Info.plist" CFBundleShortVersionString);
	echo "$version in Applications..." 
			if [ "$version" = "$current_version" ] ; then
				Result1="OK"
			elif [ "$version" != "$current_version" ] ; then
# If we find an outdated version flag the machine & exit
				Result1="Flagged"
			fi
# If we have nothing to check then we exit
else
		Result1="Not Found"
fi

# If any result is flagged...
if [ "$Result1" == "Flagged" ]; then
	Result="Flagged"
elif [ "$Result2" == "Flagged" ]; then
	Result="Flagged"
# Otherwise, test to see if the two match, and assign...
elif test "$Result1" = "$Result2"; then
	Result="$Result1"
# Otherwise check for an OK condition...
elif [[ "$Result1" == "OK" && "$Result2" == "Not Found" ]]; then
	Result="OK"
elif [[ "$Result2" == "OK" && "$Result1" == "Not Found" ]]; then
	Result="OK"
# Finally, error if the whole thing goes south...
else
	Result="error"
fi

echo "<result>$Result</result>"
exit 0
