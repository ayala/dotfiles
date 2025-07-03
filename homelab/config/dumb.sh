#!/bin/bash

# ANSI escape codes for colors
GREEN='\033[0;32m' # Green text
RED='\033[0;31m'   # Red text
BLUE='\033[1;34m' # Blue text
NC='\033[0m'      # No Color (resets to default)

clear # Clear the terminal for a clean start

cat << EOF

 ┌─────────────────────────────────────────╮
 │  ___  _  _ _  _ ___                     │
 │  |__\ |__| |\/| |--]  LXC STACK U24.04  │
 │                                         │
 ╰─────────────────────────────────────────╯

EOF

echo -e "${BLUE}Welcome to the Proxmox LXC Container Creation Script!${NC}"
echo -e "${BLUE}Please provide the following details to customize your container:${NC}"

# Prompt for CTID
read -p "$(echo -e "${GREEN}Enter Container ID (e.g., 101): ${NC}")" CTID

# OS_TEMPLATE - RECOMMENDED: Use LTS for stability
OS_TEMPLATE="local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
BRIDGE="vmbr0"

# Automatically set IP_ADDRESS based on CTID
IP_ADDRESS="10.1.1.${CTID}/24"
echo -e "${GREEN}IP Address will be set to: ${IP_ADDRESS}${NC}"

GATEWAY="10.1.1.1"

# Prompt for HOSTNAME
read -p "$(echo -e "${GREEN}Enter Container Hostname (e.g., ubuntu): ${NC}")" HOSTNAME

# Prompt for ROOT_PASSWORD
read -s -p "$(echo -e "${GREEN}Enter Root Password for the container: ${NC}")" ROOT_PASSWORD
echo

UNPRIVILEGED="1"
OSTYPE="ubuntu"
ARCH="amd64"

# Prompt for CORES
read -p "$(echo -e "${GREEN}Enter Number of CPU Cores (e.g., 4): ${NC}")" CORES

# Prompt for MEMORY
read -p "$(echo -e "${GREEN}Enter Memory in MB (e.g., 12288 for 12GB): ${NC}")" MEMORY

# Prompt for SWAP
read -p "$(echo -e "${GREEN}Enter Swap Space in MB (e.g., 8192 for 8GB): ${NC}")" SWAP

# Prompt for ROOTFS_SIZE
read -p "$(echo -e "${GREEN}Enter Root Filesystem Size in GB (e.g., 80): ${NC}")" ROOTFS_SIZE

ONBOOT="1"
FEATURES="fuse=1,nesting=1"
DESCRIPTION="Ubuntu 24.04 LTS Plex Container"
PROTECTION="0"
TEMPLATE_FLAG="0"
TAGS="ubuntu,plex"
CPULIMIT="0"
CPUUNITS="1024"
START_CT="1"

# Prompt for NEW_USERNAME
read -p "$(echo -e "${GREEN}Enter New Username for the container (e.g., ea): ${NC}")" NEW_USERNAME

# Prompt for NEW_USER_PASSWORD
read -s -p "$(echo -e "${GREEN}Enter Password for the new user: ${NC}")" NEW_USER_PASSWORD
echo

echo -e "${GREEN}Creating Proxmox LXC container $CTID...${NC}"

pct create "$CTID" "$OS_TEMPLATE" \
  --net0 "name=eth0,bridge=$BRIDGE,ip=$IP_ADDRESS,gw=$GATEWAY" \
  --hostname "$HOSTNAME" \
  --password "$ROOT_PASSWORD" \
  --unprivileged "$UNPRIVILEGED" \
  --ostype "$OSTYPE" \
  --arch "$ARCH" \
  --cores "$CORES" \
  --memory "$MEMORY" \
  --swap "$SWAP" \
  --rootfs "black:$ROOTFS_SIZE" \
  --onboot "$ONBOOT" \
  --features "$FEATURES" \
  --description "$DESCRIPTION" \
  --protection "$PROTECTION" \
  --template "$TEMPLATE_FLAG" \
  --tags "$TAGS" \
  --cpulimit "$CPULIMIT" \
  --cpuunits "$CPUUNITS" \
  --start "$START_CT"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error creating container $CTID. Exiting.${NC}"
    exit 1
fi

echo -e "${BLUE}Waiting for container $CTID to start and obtain network...${NC}"
sleep 10

echo -e "${GREEN}Executing setup commands inside container $CTID...${NC}"

pct exec "$CTID" -- bash -c "
    set -e

    # Initial system update and essential tools installation
    apt update && apt upgrade -y
    apt install -y sudo curl gnupg ca-certificates openssh-server

    # Enable root login for SSH (consider alternatives for security)
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart ssh

    # User setup
    useradd -m -s /bin/bash $NEW_USERNAME
    echo \"$NEW_USERNAME:$NEW_USER_PASSWORD\" | chpasswd
    usermod -aG sudo $NEW_USERNAME

    # Comprehensive MOTD cleanup and disabling
    echo -n > /etc/motd
    echo -n > /var/run/motd.dynamic
    chmod -x /etc/update-motd.d/*

    if [ -f /etc/init.d/motd ]; then
        chmod -x /etc/init.d/motd
    fi

    # Clean up apt cache
    apt clean
    rm -rf /var/lib/apt/lists/*
"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error during setup inside container $CTID. Please check logs.${NC}"
    exit 1
else
    echo -e "${GREEN}Container $CTID setup complete. SSH is enabled.${NC}"
    echo -e "${GREEN}User \"$NEW_USERNAME\" was added with sudo permissions. MOTD was cleared and disabled. ${NC}"
    echo -e "${BLUE}You can now access your container via SSH at $(echo "$IP_ADDRESS" | cut -d'/' -f1)${NC}"
fi
