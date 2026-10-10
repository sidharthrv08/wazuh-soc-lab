#!/bin/bash
# ==============================================================================
# Script: attack-recon-scan.sh
# Description: Simulates network reconnaissance using Nmap
# Language: Pure Bash / Nmap (Zero Python)
# Triggers: Network connection spikes, service probes (MITRE T1046)
# ==============================================================================

TARGET_IP="${1:-127.0.0.1}"

echo "[*] ==================================================="
echo "[*] SOC LAB ATTACK SIMULATION: Network Reconnaissance"
echo "[*] Target: $TARGET_IP"
echo "[*] MITRE ATT&CK: T1046 (Network Service Discovery)"
echo "[*] ==================================================="

if ! command -v nmap &> /dev/null; then
  echo "[-] Nmap not found. Installing nmap..."
  sudo apt-get update -y && sudo apt-get install -y nmap
fi

echo "[*] Launching SYN Stealth Scan against top 100 ports..."
nmap -sS -Pn --top-ports 100 "$TARGET_IP"

echo ""
echo "[*] Launching aggressive service version and OS detection against common ports..."
nmap -sV -sC -p 22,80,443,1514,1515 "$TARGET_IP"

echo ""
echo "[+] Reconnaissance scan finished."
echo "[+] Check Wazuh Dashboard Security Events for rapid connection attempts and audit events."
