#!/bin/bash
# Julian
# 24.07.2017
# Comment:
# Script läuft nach dem Start des RPI und Dauerschleife
# wenn beide G-tags 5 Schleifendurchläufe nicht erkannt werden
# wird auf Status Abwesend gesetzt

ncounter=1
daheim=2

# Whitelist clear
sudo hcitool lewlclr

# G-tags 2 Stück im Einsatz
sudo hcitool lewladd "7C:2F:xx:xx:46:xx"
sudo hcitool lewladd "7C:2F:xx:xx:46:yy"

while true; do
    sudo hcitool lescan --whitelist > scan.txt & sleep 3 && sudo pkill --signal SIGINT hcito   
    NUMOFLINES=$(wc -l < "scan.txt")
    #echo $NUMOFLINES
    if [ "$NUMOFLINES" -gt "1" ]; then
        while read -r line; do   
    	    line=${line:0:17}
    	    check=${line:0:7}
    	    if [ "$check" != "LE Scan" ]; then
    	        if [ "$line" == "7C:2F:xx:xx:46:xx" ] || [ "$line" == "7C:2F:xx:xx:46:yy" ]; then
		    ncounter=1
                    if [ "$daheim" == "0" ] || [ "$daheim" == "2" ]; then
                        daheim=1
                        echo $line "Anwesend"
			# Hier URL Aufruf für Homee Webhook
                    fi
                fi
    	    fi
        done <scan.txt 
    else
        if [ "$daheim" == "1" ]; then
	   echo "Counter Abwesend: " $ncounter
	   if [ "$ncounter" == "5" ]; then
               echo "Abwesend"
	       # Hier URL Aufruf für Homee Webhook
               daheim=0
           fi
	   ncounter=$[ncounter+ 1]
        fi
    fi
    sleep 2
done
