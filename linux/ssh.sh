#!/usr/bin/env bash

RED_BG=$'\033[1;97;41m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[33m'
GREEN=$'\033[1;32m'
RED=$'\033[1;31m'
R=$'\033[0m'

echo '-----SSH Keys-----'
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

echo '-----Root SSH Accessible-----'
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

