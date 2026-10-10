#!/bin/bash
# ==============================================================================
# Script: install-agent.sh
# Description: Automated Wazuh Agent installation for Kali Linux / Debian
# Language: Pure Bash (Zero Python Required)
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (use sudo)."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: sudo bash install-agent.sh <WAZUH_MANAGER_IP>"
  echo "Example: sudo bash install-agent.sh 192.168.100.10"
  exit 1
fi

MANAGER_IP="$1"

echo "[*] Step 1: Installing dependencies..."
apt-get update -y
apt-get install -y curl apt-transport-https gnupg2 auditd audispd-plugins

echo "[*] Step 2: Adding Wazuh GPG key and APT repository..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update -y

echo "[*] Step 3: Installing Wazuh Agent..."
WAZUH_MANAGER="$MANAGER_IP" apt-get install -y wazuh-agent

echo "[*] Step 4: Configuring and enabling Auditd..."
systemctl enable auditd
systemctl restart auditd

echo "[*] Step 5: Enabling and starting Wazuh Agent service..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent

echo "[+] Wazuh Agent successfully installed and connected to Manager: $MANAGER_IP"
echo "[+] Verify agent status: sudo systemctl status wazuh-agent"
