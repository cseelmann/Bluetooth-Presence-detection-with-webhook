#!/bin/bash
# Julian
# 24.07.2017
# Comment:
# Script läuft nach dem Start des RPI und Dauerschleife
# wenn beide G-tags 15 Schleifendurchläufe nicht erkannt werden
# wird auf Status Abwesend gesetzt

# -------------------------
# Einstellungen (edit here)
# -------------------------
away=15 	# nach wieviel Durchläufen Status "abwesend"?
gtags=("7C:2F:80:90:22:22" "7C:2F:80:90:33:55")	# G-tags mac Adresses

homeeip="192.168.178.5"
homeeport="7681"
webhooks_key="AAAAAAAAAAAAABBBBBBBBBBCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDDDEEEEEEEE"

# ----------------------
# do not edit below here 
# ----------------------
# Startverzögerung
sleep 10
ncounter=1
daheim=0

# Whitelist clear
sudo hcitool lewlclr
# G-tags zur Whitelist
echo "Gültige G-tags"
for i in ${gtags[@]}; do
	echo "$i"
	sudo hcitool lewladd "$i"
done
echo ""

while true; do
    sudo hcitool lescan --whitelist > scan.txt & sleep 2 && sudo pkill --signal SIGINT hcito   
    NUMOFLINES=$(wc -l < "scan.txt")
    if [ "$NUMOFLINES" -gt "1" ]; then
		# Anwesend
		if [ "$daheim" -eq 0 ]; then
			echo "Status: anwesend"	
			curl "http://$homeeip:$homeeport/api/v2/webhook_trigger?webhooks_key=$webhooks_key&event=anwesend"	
			daheim=1
		fi
		ncounter=1
    else
		# Abwesend
		if [ "$ncounter" -lt "$away" ]; then
			echo "Counter Abwesend: " $ncounter
		fi
		
		if [ "$ncounter" == "$away" ]; then
			echo "Status: abwesend"
			curl "http://$homeeip:$homeeport/api/v2/webhook_trigger?webhooks_key=$webhooks_key&event=abwesend"
			daheim=0
		fi
		ncounter=$[ncounter+ 1]
    fi
    sleep 1
done
