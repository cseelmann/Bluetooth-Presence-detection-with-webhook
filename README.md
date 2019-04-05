# Bluetooth Presence Scanner bluetooth_presence_scanner.sh
Bash script to detect presence of bluetooth device/tag to send webhooks per user/allaway. Requires bluetoothd.

I use some Tile Mates to detect presence, the Tiles had to be paired with the iOS App and the App had to be deleted afterwards, as Tiles did not advertise via bluetooth if paired with the app (due to peripheral connection). 

Change script settings (bluetooth MAC and Username(s), as well as webhook token and destination. 

For my Tiles I had to add the --random parameter to hcitool lewladd. Might work differently for you, please try on the commandline before blaming the script with:

hcitool lewladd --random $MAC

Script detects if already running. Install via cronjob:

Console: crontab -e

```* * * * * root $PATH_TO_SCRIPT/bluetooth_presence_scanner.sh > /dev/null 2>&1```

Thanks to https://github.com/mavnezz/proHomeeStatus, as I forked the project.
