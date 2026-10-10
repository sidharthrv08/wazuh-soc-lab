# SOC Analyst Incident Response Playbook

A standard operating procedure (SOP) for investigating and responding to security alerts triggered in the Wazuh SOC Home Lab.

---

## 1. Incident Handling Lifecycle (NIST SP 800-61 Rev. 2)

```
+---------------+     +---------------+     +---------------+     +---------------+
|  Preparation  | --> | Detection &   | --> | Containment,  | --> | Post-Incident |
|               |     | Analysis      |     | Eradication & |     | Activity      |
|               |     |               |     | Recovery      |     |               |
+---------------+     +---------------+     +---------------+     +---------------+
```

---

## 2. Playbook 1: SSH Brute-Force Alert (Rule ID 5712 / 100002)

### Step 1: Detection & Initial Triage
1. Review the alert metadata in Wazuh:
   - Source IP (`srcip`)
   - Target Usernames attempted
   - Failure frequency per minute
2. Determine if any subsequent attempt succeeded:
   - Filter query: `rule.id: 5715` (`SSHD authentication success`) AND `srcip: <ATTACKER_IP>`
   - **If a login succeeded**: Escalate immediately to **Severity 1 (Critical Compromise)**.
   - **If all failed**: Treat as **Severity 3 (Active Recon / Brute Force Attempt)**.

### Step 2: Containment
1. If the source is an unauthorized external IP or compromised internal host, block the IP using `iptables` or Wazuh Active Response:
   ```bash
   sudo iptables -A INPUT -s <ATTACKER_IP> -j DROP
   ```
2. If SSH is not strictly needed externally, disable password authentication in `/etc/ssh/sshd_config`:
   ```text
   PasswordAuthentication no
   PubkeyAuthentication yes
   ```

### Step 3: Eradication & Recovery
- Flush current failed login counters (`faillog -r`).
- Verify SSH service configuration and restart (`sudo systemctl restart ssh`).

---

## 3. Playbook 2: File Integrity Alert on Sensitive File (Rule ID 550 / 100001)

### Step 1: Detection & Initial Triage
1. Navigate to **Integrity Monitoring** -> **Events**.
2. Identify the modified path (e.g., `/etc/passwd`).
3. Check the auditd log corresponding to the event timestamp:
   ```bash
   sudo ausearch -f /etc/passwd -ts recent
   ```
   Identify:
   - Executable path (`exe`)
   - Effective User ID (`euid`)
   - Terminal or process command line (`cmdline`)

### Step 2: Containment
1. Check for newly spawned processes by the compromised user/process:
   ```bash
   ps -u <USER_ID> -o pid,user,cmd
   ```
2. Terminate rogue processes:
   ```bash
   sudo kill -9 <PID>
   ```

### Step 3: Eradication & Remediation
1. Inspect `/etc/passwd` for unauthorized UID 0 accounts:
   ```bash
   awk -F: '($3 == 0) {print}' /etc/passwd
   ```
2. Remove any rogue lines found.
3. Check `/root/.ssh/authorized_keys` and user crontabs for persistence artifacts:
   ```bash
   cat /root/.ssh/authorized_keys
   crontab -l
   ls -la /etc/cron.*
   ```

---

## 4. Post-Incident & Lessons Learned
1. Document the incident timeline, indicators of compromise (IOCs), and root cause.
2. Update custom Wazuh detection rules to reduce mean time to detect (MTTD).
3. If an automated response action was successful (or missing), configure Wazuh Active Response (`active-response`) to automatically drop IPs on repeated brute force.
