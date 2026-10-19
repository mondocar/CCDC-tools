#!/usr/bin/env bash

RED_BG=$'\033[1;97;41m'
YELLOW=$'\033[33m'
GREEN=$'\033[1;32m'
RED=$'\033[1;31m'
R=$'\033[0m'

echo "-----SSH keys-----"
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
