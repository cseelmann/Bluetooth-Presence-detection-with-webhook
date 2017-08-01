#!/bin/bash
# Julian
# 01.08.2017

# -------------------------
# Einstellungen (edit here)
# -------------------------

# nach wieviel Durchläufen Status "abwesend"?
away=15 	

# G-tags mac Adresses
gtags=("7C:2F:80:90:xx:xx;kristina" "7C:2F:80:90:yy:yy;julian")	

# Webhook senden wenn alle abwesend sind?
# Webhook für jede Person wird eh gesendet
# for_all=true		ja
# for_all=false		nein
for_all=true

# homee Einstellungen lokales Netzwerk
homeeip="192.168.178.5"
homeeport="7681"
webhooks_key="AAAAAAAAAAAAABBBBBBBBBBCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDDDEEEEEEEE"

# ----------------------
# do not edit below here 
# ----------------------

# Mehrfachausführung verhindern
script="${0##*/}"
for pid in $(pidof -x $script); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : $script : Process is already running with PID $pid"
        exit 1
    fi
done
reset

# Startverzögerung
echo "G-tag Scanner for homee"
echo ""
i=5
while [ $i -gt 0 ]; do
	#sleep 1
	echo "starts in "$i
	i=$[$i-1]
done

declare -A AThome 
declare -A AThome_counter 
declare allaway_hook=false
# Whitelist clear
sudo hcitool lewlclr
# G-tags zur Whitelist
echo "Gültige G-tags"
	for i in ${gtags[@]}; do
		echo $i
		sudo hcitool lewladd ${i:0:17}
		AThome[${i:18}]=false
		AThome_counter[${i:18}]=0
		if [ $? -eq 1 ]; then
			echo "Bluetooth error; not installed?"
			exit
		fi
	done
echo ""
 
while true; do
	sleep 1
    sudo hcitool lescan --whitelist > scan.txt & sleep 2 && sudo pkill --signal SIGINT hcito   
	reset

	while read -r line; do 
		if [ "${line:0:7}" != "LE Scan" ]; then			
			for ((index=0; index<${#gtags[@]}; index++)); do 		
				if [ "${gtags[$index]:0:17}" = ${line:0:17} ]; then
					user="${gtags[$index]:18}"
					AThome_counter[$user]=0	
					if [ ${AThome[$user]} = false ]; then
						AThome[$user]=true
						allaway_hook=false
						curl "http://$homeeip:$homeeport/api/v2/webhook_trigger?webhooks_key=$webhooks_key&event="$user"_anwesend"	
					fi
				fi
			done
		fi
	done <scan.txt

	# Abwesenheit prüfen
	for i in "${!AThome_counter[@]}"; do
		if [ ${AThome_counter[$i]} -eq "$away" ]; then
			AThome[$i]=false
			curl "http://$homeeip:$homeeport/api/v2/webhook_trigger?webhooks_key=$webhooks_key&event="$i"_abwesend"
		fi
	done
	
	# Abwesenheit um 1 hochsetzen
	for i in "${!AThome_counter[@]}"; do
		if [ ${AThome[$i]} = false ]; then
			status="abwesend"
		else
			status="anwesend"
		fi
		echo ""
		echo "User: $i"
		echo "Status: $status"
		echo "Counter: ${AThome_counter[$i]} ($away)"	 
		echo "Webhooks: "$i"_anwesend; "$i"_abwesend"
		AThome_counter["$i"]=$((${AThome_counter[$i]}+1))			
	done
		

	# Abwesend setzten wenn alle weg sind
	if [ "$for_all" = true ]; then
		allaway=true	
		for i in "${!AThome[@]}"; do
			if [ ${AThome[$i]} = true ]; then
				allaway=false
			fi
		done	
		if [ "$allaway" = true ]; then
			if [ "$allaway_hook" = false ]; then
				allaway_hook=true
				curl "http://$homeeip:$homeeport/api/v2/webhook_trigger?webhooks_key=$webhooks_key&event=alle_abwesend"
			fi
		fi
		
		if [ "$allaway" = true ]; then
			status="abwesend"
		else
			status="anwesend"
		fi
		
		echo ""
		echo "User: alle"
		echo "Status: $status"
		echo "Webhook: alle_abwesend"
	fi	
done
