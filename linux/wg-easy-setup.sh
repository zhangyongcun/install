#!/bin/bash

# WireGuard Easy Docker Setup Script
# Interactive script to deploy wg-easy container

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════╗"
echo "║   WireGuard Easy Docker Setup Script      ║"
echo "║   Interactive Configuration Tool           ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if Docker is installed
echo -e "${YELLOW}[1/8] Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed!${NC}"
    echo -e "${YELLOW}Please install Docker first:${NC}"
    echo "  - macOS: https://docs.docker.com/desktop/install/mac-install/"
    echo "  - Linux: https://docs.docker.com/engine/install/"
    echo "  - Windows: https://docs.docker.com/desktop/install/windows-install/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker daemon is not running!${NC}"
    echo -e "${YELLOW}Please start Docker and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed and running${NC}\n"

# Function to read input with default value
read_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    if [ -n "$default" ]; then
        read -p "$(echo -e ${GREEN}${prompt}${NC} [default: ${BLUE}${default}${NC}]: )" input
        eval $var_name="${input:-$default}"
    else
        while true; do
            read -p "$(echo -e ${GREEN}${prompt}${NC} [required]: )" input
            if [ -n "$input" ]; then
                eval $var_name="$input"
                break
            else
                echo -e "${RED}This field is required!${NC}"
            fi
        done
    fi
}

# Function to generate random password
generate_password() {
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16
}

# Function to generate bcrypt hash
generate_password_hash() {
    local password="$1"
    # Use official method from wg-easy documentation
    # wgpw outputs: PASSWORD_HASH='$2a$12$...'
    # We need to extract just the hash value between the quotes
    local output=$(docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$password" 2>/dev/null)
    # Extract the hash value between single quotes
    echo "$output" | sed "s/PASSWORD_HASH='\(.*\)'/\1/" | tr -d '[:space:]'
}


echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}       Basic Configuration                ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}\n"

# 1. WG_HOST (required)
echo -e "${YELLOW}[2/8] WireGuard Host Configuration${NC}"
echo "Enter the public IP address or domain name of your server"
read_with_default "WG_HOST (IP or domain)" "" WG_HOST
echo ""

# 2. WG_PORT (default: 51820)
echo -e "${YELLOW}[3/8] WireGuard Port Configuration${NC}"
echo "This is the UDP port that WireGuard will listen on"
read_with_default "WG_PORT" "51820" WG_PORT
echo ""

# 3. Web UI Port (default: 51821)
echo -e "${YELLOW}[4/8] Web Management Port Configuration${NC}"
echo "This is the TCP port for the web management interface"
read_with_default "Web UI Port" "51821" WEB_PORT
echo ""

# 4. WG_DEFAULT_ADDRESS (default: 10.8.0.x)
echo -e "${YELLOW}[5/8] VPN Network Configuration${NC}"
echo "Default VPN network segment (use .x for automatic assignment)"
echo "Examples: 10.8.0.x, 10.11.0.x, 192.168.99.x"
read_with_default "WG_DEFAULT_ADDRESS" "10.8.0.x" WG_DEFAULT_ADDRESS
echo ""

# 5. WG_ALLOWED_IPS (default: 0.0.0.0/0)
echo -e "${YELLOW}[6/8] Allowed IPs Configuration${NC}"
echo "Which networks should be routed through VPN"
echo "  - 0.0.0.0/0 : All traffic (full tunnel)"
echo "  - 192.168.8.0/24 : Only local network"
read_with_default "WG_ALLOWED_IPS" "0.0.0.0/0" WG_ALLOWED_IPS
echo ""

# 6. WG_DEFAULT_DNS (default: 119.29.29.29)
echo -e "${YELLOW}[7/8] DNS Server Configuration${NC}"
echo "DNS server for VPN clients"
echo "  - 119.29.29.29 (DNSPod China)"
echo "  - 1.1.1.1 (Cloudflare)"
echo "  - 8.8.8.8 (Google)"
read_with_default "WG_DEFAULT_DNS" "119.29.29.29" WG_DEFAULT_DNS
echo ""

# 7. PASSWORD
echo -e "${YELLOW}[8/8] Web UI Password Configuration${NC}"
random_password=$(generate_password)
echo "Set a password for the web management interface"
read_with_default "Password" "$random_password" WEB_PASSWORD
echo ""

# Generate password hash (required by wg-easy v14+)
echo -e "${YELLOW}Generating password hash...${NC}"
PASSWORD_HASH=$(generate_password_hash "$WEB_PASSWORD")

if [ -z "$PASSWORD_HASH" ]; then
    echo -e "${RED}✗ Failed to generate password hash!${NC}"
    echo -e "${YELLOW}This usually means the wg-easy Docker image cannot be pulled.${NC}"
    echo -e "${YELLOW}Please check your network connection and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Password hash generated successfully${NC}"
echo -e "${BLUE}Hash: ${PASSWORD_HASH}${NC}"
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}       Configuration Summary                ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "WG_HOST:              ${GREEN}${WG_HOST}${NC}"
echo -e "WG_PORT:              ${GREEN}${WG_PORT}${NC}"
echo -e "Web UI Port:          ${GREEN}${WEB_PORT}${NC}"
echo -e "WG_DEFAULT_ADDRESS:   ${GREEN}${WG_DEFAULT_ADDRESS}${NC}"
echo -e "WG_ALLOWED_IPS:       ${GREEN}${WG_ALLOWED_IPS}${NC}"
echo -e "WG_DEFAULT_DNS:       ${GREEN}${WG_DEFAULT_DNS}${NC}"
echo -e "Web Password:         ${GREEN}${WEB_PASSWORD}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}\n"

# Confirm
read -p "$(echo -e ${YELLOW}Do you want to proceed with this configuration? [Y/n]: ${NC})" confirm
confirm=${confirm:-Y}

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${RED}Setup cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting WireGuard Easy container...${NC}"

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^wg-easy$'; then
    echo -e "${YELLOW}Container 'wg-easy' already exists.${NC}"
    read -p "$(echo -e ${YELLOW}Do you want to remove it and create a new one? [y/N]: ${NC})" remove_confirm
    remove_confirm=${remove_confirm:-N}

    if [[ $remove_confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Stopping and removing existing container...${NC}"
        docker stop wg-easy >/dev/null 2>&1 || true
        docker rm wg-easy >/dev/null 2>&1 || true
        echo -e "${GREEN}✓ Existing container removed${NC}"
    else
        echo -e "${RED}Setup cancelled. Please remove the existing container manually.${NC}"
        exit 1
    fi
fi

# Execute docker run
echo -e "${YELLOW}Executing Docker command...${NC}\n"

# Print the docker run command for debugging
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}       Docker Run Command (for debugging)  ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
cat <<EOF
docker run -d \\
  --name=wg-easy \\
  -e "WG_HOST=${WG_HOST}" \\
  -e "LANG=cn" \\
  -e "WG_PORT=${WG_PORT}" \\
  -e "PASSWORD_HASH=${PASSWORD_HASH}" \\
  -e "WG_DEFAULT_ADDRESS=${WG_DEFAULT_ADDRESS}" \\
  -e "WG_DEFAULT_DNS=${WG_DEFAULT_DNS}" \\
  -e "WG_ALLOWED_IPS=${WG_ALLOWED_IPS}" \\
  -v ~/.wg-easy:/etc/wireguard \\
  -p "${WG_PORT}:${WG_PORT}/udp" \\
  -p "${WEB_PORT}:51821/tcp" \\
  --cap-add=NET_ADMIN \\
  --cap-add=SYS_MODULE \\
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \\
  --sysctl="net.ipv4.ip_forward=1" \\
  --restart unless-stopped \\
  ghcr.io/wg-easy/wg-easy
EOF
echo -e "${BLUE}═══════════════════════════════════════════${NC}\n"

# Execute the command
docker run -d \
  --name=wg-easy \
  -e "WG_HOST=${WG_HOST}" \
  -e "LANG=cn" \
  -e "WG_PORT=${WG_PORT}" \
  -e "PASSWORD_HASH=${PASSWORD_HASH}" \
  -e "WG_DEFAULT_ADDRESS=${WG_DEFAULT_ADDRESS}" \
  -e "WG_DEFAULT_DNS=${WG_DEFAULT_DNS}" \
  -e "WG_ALLOWED_IPS=${WG_ALLOWED_IPS}" \
  -v ~/.wg-easy:/etc/wireguard \
  -p "${WG_PORT}:${WG_PORT}/udp" \
  -p "${WEB_PORT}:51821/tcp" \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart unless-stopped \
  ghcr.io/wg-easy/wg-easy

# Check if container started successfully
echo -e "${YELLOW}Waiting for container to start...${NC}"
sleep 5

if docker ps --filter "name=wg-easy" --format '{{.Names}}' | grep -q '^wg-easy$'; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✓ WireGuard Easy Started Successfully ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"

    # Check for any errors in logs
    echo -e "\n${YELLOW}Checking container logs for errors...${NC}"
    sleep 2
    if docker logs wg-easy 2>&1 | grep -i "error\|fail" | head -5; then
        echo -e "${YELLOW}⚠ Some errors detected in logs. Container may still be functional.${NC}"
    else
        echo -e "${GREEN}✓ No errors detected in logs${NC}"
    fi
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}       Access Information                   ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "Management URL:  ${GREEN}http://${WG_HOST}:${WEB_PORT}${NC}"
    echo -e "Password:        ${GREEN}${WEB_PASSWORD}${NC}"
    echo ""
    echo -e "WireGuard Port:  ${GREEN}${WG_PORT}/udp${NC}"
    echo -e "VPN Network:     ${GREEN}${WG_DEFAULT_ADDRESS%.*}.0/24${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Open the management URL in your browser"
    echo "2. Login with the password shown above"
    echo "3. Create WireGuard client configurations"
    echo "4. Download and import configs to your devices"
    echo ""
    echo -e "${YELLOW}Useful commands:${NC}"
    echo -e "  View logs:     ${GREEN}docker logs -f wg-easy${NC}"
    echo -e "  Stop:          ${GREEN}docker stop wg-easy${NC}"
    echo -e "  Start:         ${GREEN}docker start wg-easy${NC}"
    echo -e "  Restart:       ${GREEN}docker restart wg-easy${NC}"
    echo -e "  Remove:        ${GREEN}docker rm -f wg-easy${NC}"
    echo ""
else
    echo -e "${RED}✗ Failed to start container!${NC}"
    echo -e "${YELLOW}Check logs with: docker logs wg-easy${NC}"
    exit 1
fi
