#!/usr/bin/env bash

RED_BG=$'\033[1;97;41m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
RED=$'\033[1;31m'
R=$'\033[0m'

echo '-----UID 0 Users (not root)-----'
out=$(awk -F : '$3==0 && $1!="root"' /etc/passwd)
echo "${RED_BG}${out}${R}"

echo '-----Home Directory-----'
out=$(awk -F : '$6=="/tmp" || $6=="/dev/shm"' /etc/passwd)
echo "${YELLOW}${out}${R}"

echo '-----Shell Access-----'
out=$(awk -F : 'NR==FNR {if (/^\//) list[$1]; next} $7 in list' /etc/shells /etc/passwd)
echo "${YELLOW}${out}${R}"

echo '-----Password-----'
out=$(awk -F : '$2 !~ /^[!*x]$/ && $2 != ""' /etc/passwd)
out2=$(awk -F : '$2==""' /etc/passwd)
echo "${RED}${out}${R}"
echo "${RED_BG}${out2}${R}"
