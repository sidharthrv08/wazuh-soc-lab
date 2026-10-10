# Attack Simulation & Threat Detection Guide

This guide details the execution of simulated adversary attacks against your Kali Linux endpoint and walks you through validating the resulting security alerts in the Wazuh Dashboard.

All attacks use standard Linux binaries and Bash utilities—**no Python required**.

---

## Simulation 1: SSH Brute-Force Attack

### Objective
Simulate an attacker attempting unauthorized remote access via credential stuffing against SSH service.

### MITRE ATT&CK Mapping
- **Technique**: [T1110 - Brute Force](https://attack.mitre.org/techniques/T1110/)
- **Sub-technique**: T1110.001 (Password Guessing)

### Execution (On Kali or from Host/Another VM)
Run the automated bash simulation script:
```bash
bash scripts/attack-ssh-bruteforce.sh <KALI_IP> 22
```
Or execute manual failed authentication attempts:
```bash
for i in {1..8}; do ssh -o StrictHostKeyChecking=no fakeuser$i@<KALI_IP> "exit"; done
```

### Expected Detection in Wazuh Dashboard
1. Navigate to **Modules** -> **Security Events**.
2. Filter by: `rule.id: 5710` or `rule.id: 5712`.
3. **Triggered Rules**:
   - **Rule 5710** (Level 5): `sshd: Attempt to login using a non-existent user`
   - **Rule 5712** (Level 10): `sshd: SSHD brute force trying to get access to the system`
   - **Custom Rule 100002** (Level 12): `SOC Lab Alert: SSH Brute-Force Attack detected against endpoint`

---

## Simulation 2: File Integrity Monitoring (FIM) & Backdoor Creation

### Objective
Simulate an adversary gaining access and modifying critical system authentication files (`/etc/passwd`, `/etc/shadow`) to plant an unauthorized backdoor user.

### MITRE ATT&CK Mapping
- **Technique**: [T1098 - Account Manipulation](https://attack.mitre.org/techniques/T1098/)
- **Technique**: [T1078 - Valid Accounts](https://attack.mitre.org/techniques/T1078/)

### Execution (On Kali Linux)
Run the automated FIM simulation script as root:
```bash
sudo bash scripts/attack-fim-tamper.sh
```
Or execute manually:
```bash
# Append backdoor user with UID 0 (root equivalent)
echo "badguy:x:0:0:Backdoor:/root:/bin/bash" | sudo tee -a /etc/passwd

# Wait 5 seconds, then remove to keep machine clean
sudo sed -i '/badguy/d' /etc/passwd
```

### Expected Detection in Wazuh Dashboard
1. Navigate to **Modules** -> **Integrity Monitoring**.
2. Look under the **Events** tab.
3. **Triggered Rules**:
   - **Rule 550** (Level 7): `Integrity checksum changed for: '/etc/passwd'`
   - **Rule 554** (Level 10): `File added to the system`
   - **Custom Rule 100001** (Level 10): `SOC Lab Alert: Critical system authentication file modified (/etc/passwd or /etc/shadow)`
4. The dashboard displays the exact diff, timestamp, process ID, and user account responsible for the modification.

---

## Simulation 3: Privilege Escalation Probes & Defense Evasion

### Objective
Simulate an attacker attempting unauthorized `sudo` command execution and attempting to delete command history to evade forensics.

### MITRE ATT&CK Mapping
- **Technique**: [T1548.003 - Sudo and Sudo Caching](https://attack.mitre.org/techniques/T1548/003/)
- **Technique**: [T1070.003 - Clear Command History](https://attack.mitre.org/techniques/T1070/003/)

### Execution (On Kali Linux)
Run the script:
```bash
bash scripts/attack-privesc-check.sh
```

### Expected Detection in Wazuh Dashboard
1. Navigate to **Modules** -> **Security Events**.
2. **Triggered Rules**:
   - **Rule 5404** (Level 5): `sudo: 3 incorrect password attempts`
   - **Custom Rule 100003** (Level 8): `Repeated failed sudo attempts detected for a non-root user`
   - **Custom Rule 100005** (Level 9): `Adversary command history clearing detected (Defense Evasion)`

---

## Simulation 4: Network Reconnaissance & Port Scanning

### Objective
Simulate external or internal network scanning to identify open ports, listening daemons, and potential vulnerabilities.

### MITRE ATT&CK Mapping
- **Technique**: [T1046 - Network Service Discovery](https://attack.mitre.org/techniques/T1046/)

### Execution
Run the recon script:
```bash
bash scripts/attack-recon-scan.sh <TARGET_IP>
```

### Expected Detection in Wazuh Dashboard
- Review **Security Events** and Audit events to see connection burst telemetry and socket probing activities captured by auditd and localfile log streams.

---

## How to Capture Screenshots for Your Portfolio

To make your GitHub repository stand out to interviewers:
1. **Agent Overview**: Screenshot showing Kali Linux active in **Management** -> **Endpoints Summary**.
2. **Alert Stream**: Screenshot showing the alert timeline spike in **Security Events** when running the brute-force script.
3. **FIM Comparison**: Screenshot showing the file checksum and attribute diff for `/etc/passwd` in **Integrity Monitoring**.
4. **MITRE ATT&CK Dashboard**: Screenshot of the built-in MITRE heat map with triggered techniques highlighted.
Save these images into `docs/screenshots/` and link them in your `README.md`.
