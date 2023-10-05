#!/bin/bash

############################
## Created by: Sjur Lohne ##
## Date: 23-05-2023       ##
##                        ########################################################
## A cheat sheet for how to quickly create a simple app that executes a script. ##
## You can also add an icon to the app, so it looks nice.                       ##
## This script uses osascript to ask for user input, so editing the script      ##
## manually should not be needed.                                               ##
## After the script has finished, you're left with an app in your $HOME.        ##
## You don't need to do anything else, but if you plan to use the app on other  ##
## computers you want to sign, notarize and staple it, before distribution.     ##
##################################################################################
#
##### The 8 steps below will be automatically done by this script. #####
##### I decided to keep the steps here for documentation.          #####
#
# 1. Create your script
# 2. Create a folder YOURAPP.app
# 3. Create subfolder 'Contents', and within that you create 'MacOS' and 'Resources'
# 4. Place your script in the 'MacOS' folder, and rename it to match YOURAPP(without .app or .sh)
#    The script needs to be executable, so run 'chmod +x' on it
# 5. Place your icon file in the 'Resources' folder.
#    The file can be created with the code snippet below. All you need is a png file to convert.
# 6. Place the plist file in the root of the 'Contents' folder
#
#           /YOURAPP.app
#               /Contents
#                   /MacOS
#                       your_script_here
#                   /Resources
#                       your_icns_here.icns
#                   Info.plist goes here
#
#
# Once the above steps are complete, we need to do some preparations before signing,
# notarizing and stapling.
#
# 1. Check for, and delete, hidden files like .DS_Store in the YOURAPP.app bundle
# 2. Remove all attributes for files and folders using this command:
#    'xattr -cr YOURAPP.app'
#
#################################################
##### From here, the rest is done manually. #####
#
# 3. Sign the app using codesign:
#    'codesign --deep -s "Apple Development: yourdevID@domain.dk (XYZXYZXYZ)" YOURAPP.app'
#
# Now that the app is signed, you need to notarize it.
# For this you'll first create a keychain item for your Apple ID, to be used later in the process.
# If you prefer to watch a video guide: https://www.youtube.com/watch?v=2xJcMzoi0EI
# Of course, if you already have the keychain item, you can skip step 1 & 2.
#
# 1. Run this command, and make a note of the 'WWDRTeamID', aka Team ID.
#    'xcrun altool --list-providers -u "YOUR_APPLE_ID"'
# 2. Run this command, and choose any Profile name you like, and use your App Password.
#    (To create an App Password, log on to appleid.apple.com)
#    'xcrun notarytool store-credentials --apple-id "YOUR_APPLE_ID" --password "YOUR_APP_PASSWORD" --team-id "THE_ID_FROM_STEP_1"'
# 3. You have to zip the app before submitting for notarizzation.
# 4. Now you can notarize the zip file, using this command:
#    'xcrun notarytool submit YOURAPP.zip --keychain-profile "PROFILE_NAME_FROM_STEP_2" --wait'
#
# So, now your app is notarized, the last step is to staple the app.
#
# 1. Unzip the app again.
# 2. The staple process needs to be able to write to the app bundle, so run this:
#    'chmod -R 755 YOURAPP.app'
# 3. To staple the app, simply run this command:
#    'xcrun stapler staple -v YOURAPP.app'
#
# When the app has been stapled, you can package it for distribution.
# This can be as zip, pkg or dmg.
# If you choose pkg or dmg, you need to sign and notarize the package as well.
#

# Logging
label="script2app"

function LOG() {
    echo "$(date '+%Y-%M-%d %H:%M:%S') [$label] $1" >> $HOME/Library/Logs/$label.log
}

LOG "========== LOG BEGIN =========="

UserCancelCheck() {
   if [[ -z $INPUT ]]; then
      echo "User clicked cancel"
      exit 0
   fi
}

##############################
##### Populate Variables #####
##############################

# Let the user know about the prerequisites.
osascript -e 'display dialog "This app will ask for user input, so editing the script variables manually should not be needed.\rAfter the script has finished, you are left with an app in your $HOME folder.\r\rYou dont need to do anything else, but if you plan to use the app on other computers, you want to sign, notarize and staple it, before distribution.\r\rYou will need the following:\r\r• A script you want the app to run\r• An icon PNG file" with title "Prerequisites" buttons {"Cancel","Continue"} default button 2'

# Exit the script if user clicks cancel here.
if [[ $(echo $?) == 1 ]]; then
	LOG "User clicked cancel"
	exit 0
fi

# So far so good, let continue.
# Give the project a name. This will become the name of your app.
read -r -d '' project_input <<'EOF'
   set dialogText to text returned of (display dialog "Please enter the name of your App" default answer "" buttons {"Cancel","Continue"} default button 2)
   return dialogText
EOF
INPUT=$(osascript -e "$project_input");

# Exit the script if user clicks cancel here.
UserCancelCheck
# Populate a unique variable with the data from $INPUT
PROJECT="$INPUT"

# Optional: You can give your app a version number
read -r -d '' version_input <<'EOF'
   set dialogText to text returned of (display dialog "Please enter the version of your App" default answer "1.0" buttons {"Cancel","Continue"} default button 2)
   return dialogText
EOF
INPUT=$(osascript -e "$version_input");

# Exit the script if user clicks cancel here.
UserCancelCheck
# Populate a unique variable with the data from $INPUT
VERSION="$INPUT"

# Enter path to your source icon file
read -r -d '' origicon_input <<'EOF'
   set dialogText to text returned of (display dialog "Path to the icon png file. (Drag'n Drop is supported).\rTo skip the icon, just click Continue" default answer "Skip" buttons {"Cancel","Continue"} default button 2)
   return dialogText
EOF
INPUT=$(osascript -e "$origicon_input");

# Exit the script if user clicks cancel here.
UserCancelCheck
# Populate a unique variable with the data from $INPUT
ORIGICON="$INPUT"

# Path to where you want the app to be saved
APP=$HOME/$PROJECT.app

# No need to change this one
ICONDIR="$APP/Contents/Resources/$PROJECT.iconset"

# Path to your script file
read -r -d '' script_input <<'EOF'
   set dialogText to text returned of (display dialog "Path to your script (Drag'n Drop is supported)" default answer "" buttons {"Cancel","Continue"} default button 2)
   return dialogText
EOF
INPUT=$(osascript -e "$script_input");

# Exit the script if user clicks cancel here.
UserCancelCheck
# Populate a unique variable with the data from $INPUT
SCRIPT="$INPUT"

#################################
##### Convert a PNG to ICNS #####
#################################

mkdir -pv $ICONDIR
mkdir -v $APP/Contents/MacOS

# Normal screen icons
for SIZE in 16 32 64 128 256 512; do
sips -z $SIZE $SIZE $ORIGICON --out $ICONDIR/icon_${SIZE}x${SIZE}.png ;
done

# Retina display icons
for SIZE in 32 64 256 512; do
sips -z $SIZE $SIZE $ORIGICON --out $ICONDIR/icon_$(expr $SIZE / 2)x$(expr $SIZE / 2)x2.png ;
done

# Make a multi-resolution Icon
iconutil --convert icns $ICONDIR -o $APP/Contents/Resources/$PROJECT.icns

# Delete the iconset, we don't need it anymore
if [[ -f $HOME/$PROJECT.app/Contents/Resources/$PROJECT.icns ]]; then
    rm -rf $ICONDIR
else
   LOG "Failed to create icons"
   exit 1
fi

#######################
##### Plist stuff #####
#######################

/bin/cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIconFile</key>
	<string>${PROJECT}</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
</dict>
</plist>
EOF

########################
##### Script Stuff #####
########################

# Move and rename the script
cp $SCRIPT $APP/Contents/MacOS/$PROJECT

# Make the script executable
chmod +x $APP/Contents/MacOS/$PROJECT

## Delete any .DS_Store files before notarizing.
if [[ $(ls -a | egrep '^\.D') ]]; then
   LOG "Found DS_Store file, deleting..."
   rm $(ls -a | egrep '^\.D')
fi

#  Remove all attributes
xattr -cr "$APP"

# Touch the app.
touch "$APP"

# Finishing off with some next steps.
read -r -d '' finish <<'EOF'
   display dialog "1. Sign the app using codesign:
codesign --deep -s \"Apple Development: yourdevID@domain.dk (XYZXYZXYZ)\" YOURAPP.app

After the app is signed, you need to notarize it.
For this you first create a keychain item for your Apple ID, to be used later in the process.
If you prefer to watch a video guide: https://www.youtube.com/watch?v=2xJcMzoi0EI
Of course, if you already have the keychain item, you can skip step 1 and 2 below.

1. Run this command, and make a note of the WWDRTeamID, aka Team ID:
   xcrun altool --list-providers -u \"YOUR_APPLE_ID\"
2. Run this command, and choose any Profile name you like, and use your App Password:
   xcrun notarytool store-credentials --apple-id \"YOUR_APPLE_ID\" --password \"YOUR_APP_PASSWORD\" --team-id \"THE_ID_FROM_STEP_1\"
3. Zip the app before submitting for notarization.
4. Now you can notarize the zip file, using this command:
   xcrun notarytool submit YOURAPP.zip --keychain-profile \"PROFILE_NAME_FROM_STEP_2\" --wait

So, now your app is notarized, the last step is to staple the app.

1. Unzip the app again.
2. The staple process needs to be able to write to the app bundle, so run this:
   chmod -R 755 YOURAPP.app
3. To staple the app, simply run this command:
   xcrun stapler staple -v YOURAPP.app

When the app has been stapled, you can package it for distribution.
This can be as zip, pkg or dmg.
If you choose pkg or dmg, you need to sign and notarize the package as well.

" with title "Optional next steps" buttons {"OK"}
EOF
INPUT=$(osascript -e "$finish");

exit 0