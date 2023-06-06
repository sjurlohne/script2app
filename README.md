# script2app

This project started as a simple cheat sheet for how to quickly create a simple app that executes a script.
Then I started scripting parts of it, added the icon and version number, and some info about signing, notarizing and stapling.

The source uses osascript to ask for user input, so editing the script variables manually should not be needed.

After the script has finished, you're left with an app in your $HOME. You don't need to do anything else, but if you plan to use the app on other
computers you want to sign, notarize and staple it, before distribution.
