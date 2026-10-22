#!/usr/bin/env bash

RED_BG=$'\033[1;97;41m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[33m'
GREEN=$'\033[1;32m'
RED=$'\033[1;31m'
R=$'\033[0m'

echo -e '----- UID 0 Users (not root) -----\n'
out=$(awk -F : '$3==0 && $1!="root"' /etc/passwd)
echo "${RED_BG}${out}${R}"

echo -e '\n----- Home Directory -----\n'
out=$(awk -F : '$6=="/tmp" || $6=="/var/tmp" || $6=="/dev/shm"' /etc/passwd)
echo "${YELLOW}${out}${R}"

echo -e '\n----- Shell Access -----\n'
out=$(awk -F : 'NR==FNR {if (/^\//) list[$1]; next} $7 in list' /etc/shells /etc/passwd)
echo "${YELLOW}${out}${R}"

echo -e '\n----- Password -----\n'
out=$(awk -F : '$2!~/^[!*x]$/ && $2!=""' /etc/passwd)
out2=$(awk -F : '$2==""' /etc/passwd)
echo "${RED}${out}${R}"
echo "${RED_BG}${out2}${R}"

echo -e '\n----- SSH Keys -----\n'
passwd_fields=$(awk -F : '{print $1, $3, $6}' /etc/passwd)
while read -r u uid d; do
        FILE="${d}/.ssh/authorized_keys"
        if [[ -f "$FILE" ]]; then
                KEYS=$(awk 'NF && $1 !~ /^#/' "$FILE" 2>/dev/null)
                if [[ -n "$KEYS" && "${uid}" != "0" ]]; then
                        echo "${YELLOW}${u} [uid=${uid}] has a key located at ${FILE} = ${KEYS}${R}"
                elif [[ -n "$KEYS" && "${uid}" == "0" ]]; then
                        echo "${RED_BG}${u} [uid=${uid}] has an SSH key located at ${FILE} = ${KEYS}${R}"
                else
                        echo "${GREEN}${u} [uid=${uid}] has an empty key file located at ${FILE}${R}"
                fi
        fi
done <<< "${passwd_fields}"

echo -e '\n----- Root SSH Accessible -----\n'
out=$(sudo sshd -T 2>/dev/null | grep -i permitrootlogin)
out2=$(awk '$2=="prohibit-password" || $2=="forced-commands-only" || $2=="without-password"' <<< "${out}")
out3=$(awk '$2=="yes"' <<< "${out}")
out4=$(awk '$2=="no"' <<< "${out}")
if [[ -n "$out2" ]]; then
        echo "${YELLOW}${out2}${R}"
elif [[ -n "$out3" ]]; then
        echo "${RED_BG}${out3}${R}"
elif [[ -n "$out4" ]]; then
        echo "${GREEN}${out4}${R}"
else
        echo "${CYAN}Could not determine! ${out}${R}"
fi

sockets=$(sudo ss -tupanH)
out=$(awk '{print $2, $5, $6, $7}' <<< "${sockets}")

echo -e '\n----- Active Listeners -----\n'
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

echo -e '\n----- Active Connections -----\n'
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

echo -e '\n----- Suspicious Parent Process -----\n'
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
echo -e '\n----- Suspicious Link Path -----\n'
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
