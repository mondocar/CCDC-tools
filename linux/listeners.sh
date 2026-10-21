#!/usr/bin/env bash

RED_BG=$'\033[1;97;41m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[33m'
GREEN=$'\033[1;32m'
RED=$'\033[1;31m'
R=$'\033[0m'

echo '-----Active Listeners-----'
sockets=$(sudo ss -tupanH)
out=$(awk '{print $2, $5, $7}' <<< "${sockets}")
proc_check='^(nc|ncat|netcat|socat|python[0-9.]*|perl|ruby|php|bash|sh|dash)$'
while read -r state LP info; do
	if [[ "$state" == "LISTEN" ]]; then
		procname=$(grep -oP '\(\("\K[^"]+' <<< "$info")
		pid=$(grep -oP 'pid=\K[0-9]+' <<< "$info")
		if [[ "$procname" =~ $proc_check ]]; then
			user=$(ps -o user= -p "$pid" 2>/dev/null)
			if [[ "$user" != "root" ]]; then
				echo "${RED}${user} is running ${procname} on IP:port ${LP} with the pid=${pid}${R}"
				else
				echo "${RED_BG}${user} is running ${procname} on IP:port ${LP} with the pid=${pid}${R}"
			fi
		fi
	fi
done <<< "${out}"

# echo '-----Active Connections-----'

# Check for listening connections, check user name, IP:port, and process name
# check for nc, ncat, netcat, socat, python, python3, perl, ruby, php, bash, sh, dash
# Check if root is running a listening process
#
# TODO
#
# Once found proccess, readlink /proc/PID/exe and look for /tmp /dev/shm or hidden (start with .)
# Check non root on privilege port
# Check for established connections, check for proccess user and check pid for shell access
#
#
