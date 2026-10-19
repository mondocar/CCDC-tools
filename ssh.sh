#!/usr/bin/env bash

RED_BG=$'\033[1;97;41m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[33m'
GREEN=$'\033[1;32m'
RED=$'\033[1;31m'
R=$'\033[0m'

echo "-----SSH Keys-----"
FILE="$HOME/.ssh/authorized_keys"
if [[ -f "$FILE" ]]; then
	KEYS=$(awk 'NF && $1 !~ /^#/' "$FILE" 2>/dev/null)
	if [[ -n "$KEYS" ]]; then
		out=$(cat "$FILE")
		echo "${YELLOW}${out}${R}"
	else
		echo "${GREEN}${FILE} is empty!${R}"
	fi
else
	echo "${GREEN}${FILE} does not exist!${R}"
fi

echo "-----Root SSH Accessible-----"
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

