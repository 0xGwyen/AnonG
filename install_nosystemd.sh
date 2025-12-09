#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE_ANON='\033[38;2;2;128;175m'
NOCOLOR='\033[0m'

. /etc/os-release

echo -e "${BLUE_ANON}=== Installing ANON Relay (Optimized + No-Systemd for OctaSpace) ===${NOCOLOR}"

# ----------------------------------------
# SYSTEM UPDATE + TOOLS
# ----------------------------------------

echo -e "${CYAN}Updating system & installing tools...${NOCOLOR}"
apt update -y && apt upgrade -y
apt install -y curl wget jq ufw htop net-tools bmon nload iftop

# ----------------------------------------
# KERNEL NETWORK OPTIMIZATION
# ----------------------------------------

echo -e "${CYAN}Applying kernel optimizations...${NOCOLOR}"

cat >/etc/sysctl.d/99-anon-optimized.conf <<'EOF'
# High-performance TCP tuning
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.core.rmem_default = 67108864
net.core.wmem_default = 67108864
net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
fs.file-max = 1000000
net.core.somaxconn = 65535
net.ipv4.ip_local_port_range = 1024 65535
EOF

sysctl --system

# ----------------------------------------
# INSTALL ANON PACKAGE
# ----------------------------------------

echo -e "${CYAN}Installing ANON...${NOCOLOR}"

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
# START RELAY (NO SYSTEMD)
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
    echo -e "${RED}Fingerprint generation failed.${NOCOLOR}"
    exit 1
fi

echo -e "${GREEN}ANON relay running successfully.${NOCOLOR}"
