#!/bin/bash
# Thanks to https://github.com/mavnezz/proHomeeStatus
# Need: sudo setcap 'cap_net_raw,cap_net_admin+eip' `which hcitool`
#
# -------------------------
# Settings (edit here)
# -------------------------

# bluetooth tags and user names
tags=("E8:D1:x:xx:xx:x;User A" "EA:64:xx:xx:xx:x;User B")

# workingdir - consider using a ramdisk, as a lot of i/o is generated
tmpdir="/ramdisk"
tmpfile="scan.txt"

# iterations before "away" => away * scaninterval = time to advertise leave
away=30

# interval between scans in seconds
scaninterval=15

# send additional webhook if all are away
# for_all=true	 	yes
# for_all=false		no
for_all=true

# webhook message payload after user name
returnmsg="is at home"
leavemsg="has left"
allmsg="Nobody at home"

# Webhook function, adopt to your needs. Sends payload as POST data
webhookurl="http://192.168.0.10:1880/hook"
webhooktoken="!SECRET"
sendwebhook () {
                curl -s \
                  --form-string "message=$1" \
                  --form-string "token=$2" \
                  $webhookurl > /dev/null 2>&1
}

# ----------------------
# do not edit below here
# ----------------------

# prevent multiple instances
script="${0##*/}"
for pid in $(pidof -x $script); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : $script : Process is already running with PID $pid"
        exit 1
    fi
done
sudo hciconfig hci0 down
sleep 1
sudo hciconfig hci0 up
reset

echo "Tag Scanner with webhooks"
echo ""

# Define arrays for counting
declare -A AThome
declare -A AThome_counter
declare allaway_hook=false

# Whitelist clear
sudo hcitool lewlclr
# tags into Whitelist
echo "valid tags"
	for i in ${tags[@]}; do
		echo $i
		sudo hcitool lewladd --random ${i:0:17}
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
    sudo hcitool lescan --whitelist > $tmpdir/$tmpfile & sleep $scaninterval && sudo pkill --signal SIGINT hcito
	reset

	while read -r line; do
		if [ "${line:0:7}" != "LE Scan" ]; then
			for ((index=0; index<${#tags[@]}; index++)); do
				if [ "${tags[$index]:0:17}" = ${line:0:17} ]; then
					user="${tags[$index]:18}"
					AThome_counter[$user]=0
					if [ ${AThome[$user]} = false ]; then
						AThome[$user]=true
						allaway_hook=false
            sendwebhook "$user $returnmsg" "$webhooktoken"
					fi
				fi
			done
		fi
	done <$tmpdir/$tmpfile

	# check if user is away
	for i in "${!AThome_counter[@]}"; do
		if [ ${AThome_counter[$i]} -eq "$away" ]; then
			AThome[$i]=false
      sendwebhook "$i $leavemsg" "$webhooktoken"
		fi
	done

	# increase away counter by 1
	for i in "${!AThome_counter[@]}"; do
		if [ ${AThome[$i]} = false ]; then
      status="away"
		else
			status="@home"
		fi
		echo ""
		echo "User: $i"
		echo "Status: $status"
		echo "Counter: ${AThome_counter[$i]} (max. $away)"
		AThome_counter["$i"]=$((${AThome_counter[$i]}+1))
	done

	# set away if everyone left
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
				sendwebhook "$allmsg" "$webhooktoken"
			fi
		fi
		if [ "$allaway" = true ]; then
			status="away"
		else
			status="@home"
		fi
		echo ""
		echo "User: all"
		echo "Status: $status"
		fi
done
