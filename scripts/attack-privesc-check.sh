#!/bin/bash
# ==============================================================================
# Script: attack-privesc-check.sh
# Description: Simulates unauthorized privilege escalation and defense evasion
# Language: Pure Bash (Zero Python)
# Triggers: Wazuh Rules 5404, 5402, and Custom Rules 100003, 100005
# ==============================================================================

echo "[*] ==================================================="
echo "[*] SOC LAB ATTACK SIMULATION: Privilege Escalation & Defense Evasion"
echo "[*] MITRE ATT&CK: T1548.003 (Sudo and Sudo Caching), T1070.003 (Clear History)"
echo "[*] ==================================================="

echo "[*] Step 1: Simulating repeated failed sudo privilege escalation attempts..."
for i in {1..4}; do
  echo "wrongpassword$i" | sudo -S ls /root 2>/dev/null || true
  sleep 0.5
done

echo "[*] Step 2: Attempting unauthorized read of /etc/shadow..."
cat /etc/shadow 2>/dev/null || echo "[!] Access Denied (Logged by kernel/auditd)"

echo "[*] Step 3: Simulating defense evasion technique (Clearing bash history)..."
echo "rm -f ~/.bash_history"
history -c 2>/dev/null || true

echo ""
echo "[+] Attack sequence finished."
echo "[+] Check Wazuh Dashboard:"
echo "    - Filter: 'rule.id: 5404' (Failed sudo attempt)"
echo "    - Filter: 'rule.id: 100003' (SOC Lab repeated failed sudo probe)"
echo "    - Filter: 'rule.id: 100005' (Adversary command history clearing)"
