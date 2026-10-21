#!/usr/bin/env bash

RED_BG=$'\033[1;97;41m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[33m'
GREEN=$'\033[1;32m'
RED=$'\033[1;31m'
R=$'\033[0m'

sockets=$(sudo ss -tupanH)
out=$(awk '{print $2, $5, $6, $7}' <<< "${sockets}")

echo '-----Active Listeners-----'
proc_check='^(nc|ncat|netcat|socat|python[0-9.]*|perl|ruby|php|bash|sh|dash)$'
while read -r state LP _ info; do
	if [[ "$state" == "LISTEN" ]]; then
		procname=$(grep -oP '\(\("\K[^"]+' <<< "$info")
		if [[ "$procname" =~ $proc_check ]]; then
			pid=$(grep -oP 'pid=\K[0-9]+' <<< "$info")
			read -r user uid < <(ps -o user=,uid= -p "$pid" 2>/dev/null)
			if [[ "$uid" == "0" ]]; then
				echo "${RED_BG}${user} [uid=${uid}] is running ${procname} listening on IP:port ${LP} with the pid=${pid}${R}"
			else
				echo "${RED}${user} [uid=${uid}] is running ${procname} listening on IP:port ${LP} with the pid=${pid}${R}"
			fi
		fi
	fi
done <<< "${out}"

echo '-----Active Connections-----'
while read -r state LP PP info; do
	if [[ "$state" == "ESTAB" ]]; then
		procname=$(grep -oP '\(\("\K[^"]+' <<< "$info")
		if [[ "$procname" =~ $proc_check ]]; then
			pid=$(grep -oP 'pid=\K[0-9]+' <<< "$info")
			read -r user uid ppid < <(ps -o user=,uid=,ppid= -p "$pid" 2>/dev/null)
			if [[ "$uid" == "0" ]]; then
				echo "${RED_BG}${PP} is connected to ${user} [uid=${uid}] on ${LP} through ${procname} [pid=${pid}, ppid=${ppid}]${R}"
			else
				echo "${RED}${PP} is connected to ${user} [uid=${uid}] on ${LP} through ${procname} [pid=${pid}, ppid=${ppid}]${R}"
			fi
		fi
	fi
done <<< "${out}"

echo '-----Suspicious Parent Process-----'
parent='^(cron|crond|apache2|nginx|httpd|php-fpm)$'
while read -r state _ _ info; do
	if [[ "$state" == "ESTAB" ]]; then
		procname=$(grep -oP '\(\("\K[^"]+' <<< "$info")
		if [[ "$procname" =~ $proc_check ]]; then
			pid=$(grep -oP 'pid=\K[0-9]+' <<< "$info")
			read -r user uid ppid < <(ps -o user=,uid=,ppid= -p "$pid" 2>/dev/null)
			parent_comm=$(ps -o comm= -p "${ppid}" 2>/dev/null)
			if [[ "$parent_comm" =~ $parent ]]; then
				echo "${RED_BG}${procname} [pid=${pid}] was spawned by ${parent_comm} [pid=${ppid}] through ${user} [uid=${uid}]${R}"
			fi
		fi
	fi
done <<< "${out}"
echo '-----Suspicious Link Path-----'
sus_path='(^|/)(tmp|dev/shm|var/tmp)(/|$)'
while read -r state _ _ info; do
        if [[ "$state" == "ESTAB" ]]; then
		pid=$(grep -oP 'pid=\K[0-9]+' <<< "$info")
		path=$(readlink -f /proc/"$pid"/exe 2>/dev/null)
		if [[ "$path" =~ $sus_path || "$path" =~ /\. ]]; then
			procname=$(grep -oP '\(\("\K[^"]+' <<< "$info")
			echo "${RED}${procname} [pid=${pid}] path is ${path}"
		fi
	fi
done <<< "${out}"

# TODO
#
# add exit/fail conditions
