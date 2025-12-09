#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE_ANON='\033[38;2;2;128;175m'
NOCOLOR='\033[0m'

. /etc/os-release

echo -e "${BLUE_ANON}=== Installing ANON (no-systemd mode for OctaSpace) ===${NOCOLOR}"

# Add repo
wget -qO- https://deb.en.anyone.tech/anon.asc | tee /etc/apt/trusted.gpg.d/anon.asc
echo "deb [signed-by=/etc/apt/trusted.gpg.d/anon.asc] https://deb.en.anyone.tech anon-live-$VERSION_CODENAME main" \
  | tee /etc/apt/sources.list.d/anon.list

apt-get update --yes
apt-get install anon --yes

echo -e "${GREEN}ANON installed successfully.${NOCOLOR}"


# ----------------------------------------
# CONFIG WIZARD
# ----------------------------------------

read -p "Nickname: " NICK
read -p "Contact Info: " CONTACT
read -p "ORPort [9001]: " ORPORT
ORPORT="${ORPORT:-9001}"

mkdir -p /var/log/anon
mkdir -p /var/lib/anon

cat <<EOF >/etc/anon/anonrc
Nickname $NICK
ContactInfo $CONTACT
Log notice file /var/log/anon/notices.log
ORPort $ORPORT
ControlPort 0
SocksPort 0
ExitRelay 0
ExitPolicy reject *:*
EOF

echo -e "${GREEN}Config saved to /etc/anon/anonrc${NOCOLOR}"


# ----------------------------------------
# START RELAY WITHOUT SYSTEMD
# ----------------------------------------

echo -e "${CYAN}Starting ANON relay (no systemd)...${NOCOLOR}"
anon --quiet --runasdaemon 1

sleep 5

# ----------------------------------------
# FINGERPRINT GENERATION
# ----------------------------------------

FP=/var/lib/anon/fingerprint

echo -e "${CYAN}Waiting for fingerprint generation...${NOCOLOR}"

for i in {1..20}; do
    if [ -f "$FP" ]; then
        F=$(awk '{print $2}' "$FP")
        echo -e "${GREEN}\n=== FINGERPRINT GENERATED ===${NOCOLOR}"
        echo "$F"
        echo ""
        break
    fi
    sleep 2
done

if [ ! -f "$FP" ]; then
    echo -e "${RED}Fingerprint generation failed (no systemd env).${NOCOLOR}"
    exit 1
fi

echo -e "${GREEN}ANON relay running successfully.${NOCOLOR}"
