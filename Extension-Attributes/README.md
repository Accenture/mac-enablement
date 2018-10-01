## Extension Attributes

Various Extension Attributes created for use within Jamf Pro.

### FlashEA.sh
This script will check the main Applications folder and any Adobe sub-folders for the standalone "Flash Player.app". Any copies that are found are checked against a hard-coded version number; if any of these do not match the current version then the attribute is set as "Flagged".

### Symantec Health Check.sh
This script runs several local checks of the Symantec Endpoint Protection client, and converts the individual results into a "Health Score" of eight binary numbers. 1 = OK, 0 = Fail.
