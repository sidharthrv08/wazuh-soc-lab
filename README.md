# 🛡️ Enterprise SOC Home Lab: Wazuh SIEM & Endpoint Telemetry Monitoring

[![Wazuh SIEM](https://img.shields.io/badge/SIEM-Wazuh%20v4.9-0052cc?style=for-the-badge&logo=wazuh&logoColor=white)](https://wazuh.com)
[![Virtualization](https://img.shields.io/badge/VirtualBox-7.0+-183A61?style=for-the-badge&logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)
[![Monitored Endpoint](https://img.shields.io/badge/Endpoint-Kali%20Linux%202024-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)](https://www.kali.org/)
[![SIEM Server](https://img.shields.io/badge/Server-Ubuntu%2022.04%20LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Framework](https://img.shields.io/badge/Framework-MITRE%20ATT%26CK-red?style=for-the-badge&logo=target&logoColor=white)](https://attack.mitre.org/)
[![Standard](https://img.shields.io/badge/SOP-NIST%20SP%20800--61%20Rev2-blue?style=for-the-badge)](https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

---

## 📌 Executive Summary

This repository contains the architecture, configuration scripts, custom detection rules, adversary emulation playbooks, and incident response standard operating procedures (SOPs) for an **Enterprise Security Operations Center (SOC) Home Lab**.

Built using **Wazuh SIEM/XDR platform** and **Oracle VM VirtualBox**, the lab delivers end-to-end security observability:
- **Kernel-Level Telemetry**: Continuous monitoring of process execution via Linux `auditd` (`execve`).
- **File Integrity Monitoring (FIM)**: Real-time checksum tracking (`syscheck`) on critical authentication files (`/etc/passwd`, `/etc/shadow`, `/etc/sudoers`).
- **Detection Engineering**: Custom correlation rules mapped to the **MITRE ATT&CK** framework.
- **Incident Response**: Playbooks structured around the **NIST SP 800-61 Rev. 2** lifecycle.
- **Resource Optimized**: Tailored for low-memory environments (running smoothly on host systems with **6 GB – 8 GB RAM** without Python dependencies).

---

## 🏗️ Architecture & Network Topology

The lab operates in an isolated virtual network environment (`SOCNet` / NAT Network) to ensure safe adversary emulation:

```
+---------------------------------------------------------------------------------------+
|                                HOST MACHINE (Windows 10/11)                           |
|                  SOC Analyst UI: https://<WAZUH_SERVER_IP>:443                        |
+-------------------------------------------+-------------------------------------------+
                                            |
                     +----------------------+----------------------+
                     |                                             |
+--------------------v--------------------+       +----------------v--------------------+
|         VM 1: WAZUH SIEM SERVER         |       |       VM 2: MONITORED ENDPOINT      |
|          (Ubuntu Server 22.04)          |       |             (Kali Linux)            |
|                                         |       |                                     |
|  - Wazuh Manager (Correlation Engine)   |       |  - Wazuh Agent (Telemetry Forwarder)|
|  - Wazuh Indexer (OpenSearch DB)        |<======|  - Linux Audit Daemon (auditd)      |
|  - Wazuh Dashboard (Web UI & Kibana)    | Port  |  - Syscheck (File Integrity Monitor)|
|                                         | 1514  |  - Syslog & Auth Log Collection     |
|  Static IP: 192.168.100.10              |       |  Static IP: 192.168.100.20          |
+-----------------------------------------+       +-------------------------------------+
                     |                                             |
                     +----------------------+----------------------+
                                            |
                        [ VirtualBox Internal NAT Network (SOCNet) ]
```

### Port & Communication Flow

| Service | Port | Protocol | Flow | Function |
| :--- | :--- | :--- | :--- | :--- |
| **Agent Enrollment** | `1515` | TCP | Kali &rarr; Wazuh Server | Automatic agent registration via TLS-secured `authd` |
| **Telemetry Transport** | `1514` | TCP/UDP | Kali &rarr; Wazuh Server | Encrypted transmission of system events, audit logs, and alerts |
| **Wazuh Web Dashboard** | `443` | HTTPS | Host &rarr; Wazuh Server | Web UI for threat visualization, alert triage, and dashboarding |
| **Wazuh Indexer API** | `9200` | HTTPS | Wazuh Internal | Storage, retrieval, and search API for indexed alert data |
| **SSH Administration** | `22` | TCP | Host/Kali &harr; VMs | Secure terminal access and adversary brute-force target |

---

## 🎯 Detection Engineering & MITRE ATT&CK Mapping

Custom correlation rules were authored in `/var/ossec/etc/rules/local_rules.xml` to detect adversary techniques across the intrusion lifecycle:

| Scenario / Threat | MITRE Technique | Technique ID | Emulation Script | Triggered Wazuh Rule | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Credential Access** | SSH Password Brute-Force | [T1110.001](https://attack.mitre.org/techniques/T1110/001/) | [`attack-ssh-bruteforce.sh`](scripts/attack-ssh-bruteforce.sh) | **100002** (correlating Rule 5710) | Level 12 (High) |
| **Persistence / Backdoor** | Modifying `/etc/passwd` or `/etc/shadow` | [T1078](https://attack.mitre.org/techniques/T1078/), [T1098](https://attack.mitre.org/techniques/T1098/) | [`attack-fim-tamper.sh`](scripts/attack-fim-tamper.sh) | **100001** (correlating Rule 550) | Level 10 (High) |
| **Privilege Escalation** | Sudo Abuse & Repeated Failed Probes | [T1548.003](https://attack.mitre.org/techniques/T1548/003/) | [`attack-privesc-check.sh`](scripts/attack-privesc-check.sh) | **100003** (correlating Rule 5404) | Level 8 (Medium) |
| **Command & Control** | Interactive Reverse Shell Execution | [T1059.004](https://attack.mitre.org/techniques/T1059/004/), [T1071](https://attack.mitre.org/techniques/T1071/) | Bash / Netcat listener probe | **100004** (correlating Rule 80700) | Level 13 (Critical) |
| **Defense Evasion** | Shell History Deletion (`history -c`) | [T1070.003](https://attack.mitre.org/techniques/T1070/003/) | [`attack-privesc-check.sh`](scripts/attack-privesc-check.sh) | **100005** (correlating Rule 80700) | Level 9 (Medium) |
| **Reconnaissance** | Network Port & Service Scanning | [T1046](https://attack.mitre.org/techniques/T1046/) | [`attack-recon-scan.sh`](scripts/attack-recon-scan.sh) | Dynamic port scans & audit triggers | Level 7 (Medium) |

---

## ⚙️ Hardware Sizing & Low-RAM Optimization

Configured specifically to allow high-fidelity enterprise monitoring to run on resource-constrained host machines (**6 GB to 8 GB total RAM**):

| Virtual Machine | Operating System | Allocated RAM | vCPUs | Disk Size |
| :--- | :--- | :--- | :--- | :--- |
| **Wazuh SIEM Server** | Ubuntu Server 22.04 LTS (CLI only) | **3072 MB** (3.0 GB) | 2 | 25 GB |
| **Monitored Endpoint** | Kali Linux 2024.x | **2048 MB** (2.0 GB) | 1 | 20 GB |
| **Windows Host OS** | Windows 10 / 11 | Remaining (~2.5 GB) | - | - |

### Performance Tuning Steps Applied
1. **JVM Heap Ceiling**: Set `/etc/wazuh-indexer/jvm.options` to `-Xms512m -Xmx1g` to stop memory starvation.
2. **Swapfile Configuration**: Initialized a 2 GB dedicated swapfile on the SIEM server (`fallocate -l 2G /swapfile`).
3. **Headless Execution**: Ubuntu Server runs purely headless with zero desktop environment overhead.

---

## 📁 Repository Structure

```text
wazuh-soc-lab/
├── README.md                           # Comprehensive lab overview & architecture
├── LICENSE                             # MIT License
├── .gitignore                          # Git tracking rules
├── configs/
│   ├── local_rules.xml                 # Custom Wazuh detection & correlation rules
│   ├── ossec-agent.conf                # Endpoint agent configuration (FIM & Log forwarder)
│   └── audit.rules                     # Linux audit daemon rules (execve & system calls)
├── docs/
│   ├── 01-architecture.md              # Deep-dive network topology & communication matrix
│   ├── 02-installation-guide.md        # Step-by-step setup and enrollment guide
│   ├── 03-attack-simulation-guide.md   # Adversary emulation execution & verification steps
│   └── 04-incident-response-playbook.md# NIST SP 800-61 Rev. 2 investigation playbooks
└── scripts/
    ├── install-agent.sh                # Pure Bash agent installation & enrollment automation
    ├── attack-ssh-bruteforce.sh        # SSH brute-force credential spraying simulation
    ├── attack-fim-tamper.sh            # Critical system file integrity tampering simulation
    ├── attack-privesc-check.sh         # Sudo escalation probe & defense evasion simulation
    └── attack-recon-scan.sh            # Network discovery & port scanning simulation
```

---

## 🚀 Quick Deployment Guide

### Phase 1: Virtual Networking
1. Open **VirtualBox** &rarr; **Tools** &rarr; **Network Manager** &rarr; **NAT Networks**.
2. Create a network named `SOCNet` with CIDR `192.168.100.0/24` (DHCP enabled).
3. Set Network Adapter 1 of both VMs to **NAT Network (`SOCNet`)**.

### Phase 2: Wazuh SIEM Server Deployment (Ubuntu VM)
1. On the Ubuntu Server VM, run the all-in-one assistant:
   ```bash
   curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
   sudo bash ./wazuh-install.sh -a
   ```
2. Note the generated administrator password printed in the terminal.
3. Open your host browser and verify access at `https://192.168.100.10`.

### Phase 3: Kali Endpoint Agent Enrollment
1. On the Kali Linux endpoint, execute the zero-dependency Bash installer:
   ```bash
   sudo bash scripts/install-agent.sh 192.168.100.10
   ```
2. Deploy audit rules and restart `auditd`:
   ```bash
   sudo cp configs/audit.rules /etc/audit/rules.d/wazuh-soc.rules
   sudo augenrules --load
   sudo systemctl restart auditd
   ```
3. Check agent status:
   ```bash
   sudo systemctl status wazuh-agent
   ```

### Phase 4: Install Custom Rules on Wazuh Manager
1. Copy `configs/local_rules.xml` to `/var/ossec/etc/rules/local_rules.xml` on the Wazuh Server.
2. Validate syntax and restart the manager:
   ```bash
   sudo /var/ossec/bin/wazuh-analysisd -t
   sudo systemctl restart wazuh-manager
   ```

---

## 🧪 Adversary Emulation & Verification

Run the automated simulation scripts on the Kali VM to generate telemetry and trigger alerts in the Wazuh Dashboard:

### 1. SSH Brute-Force Emulation
```bash
bash scripts/attack-ssh-bruteforce.sh
```
* **Alert Triggered**: Rule `100002` (Level 12) — Multiple failed SSH login attempts from source IP.
* **MITRE ATT&CK**: [T1110.001 (Password Guessing)](https://attack.mitre.org/techniques/T1110/001/)

### 2. File Integrity Tampering (FIM)
```bash
bash scripts/attack-fim-tamper.sh
```
* **Alert Triggered**: Rule `100001` (Level 10) — Critical system authentication file modified (`/etc/passwd`).
* **MITRE ATT&CK**: [T1098 (Account Manipulation)](https://attack.mitre.org/techniques/T1098/)

### 3. Sudo Privilege Escalation & History Tampering
```bash
bash scripts/attack-privesc-check.sh
```
* **Alerts Triggered**:
  - Rule `100003` (Level 8) — Repeated failed sudo attempts for non-root user.
  - Rule `100005` (Level 9) — Shell history deletion detected (`history -c`).
* **MITRE ATT&CK**: [T1548.003 (Sudo Abuse)](https://attack.mitre.org/techniques/T1548/003/), [T1070.003 (Clear Command History)](https://attack.mitre.org/techniques/T1070/003/)

---

## 📋 Incident Response Playbook (NIST SP 800-61 Rev. 2)

Each detected alert follows a structured triage and containment workflow:

```
[ Phase 1: Triage ] ──► [ Phase 2: Analysis ] ──► [ Phase 3: Containment ] ──► [ Phase 4: Eradication & Review ]
```

- **Triage**: Extract `srcip`, timestamp, user identity, process ID (`pid`), and command line (`cmdline`).
- **Containment**:
  - For brute-force: Drop attacker IP via `iptables` or Wazuh Active Response.
  - For account tampering: Lock suspect accounts (`passwd -l <user>`) and restore integrity from known backups.
- **Eradication**: Terminate rogue background shells, remove unauthorized SSH keys, and reset credentials.
- **Post-Incident**: Document findings in the SOC case management notes and fine-tune correlation thresholds.

*(Detailed procedures are documented in [`docs/04-incident-response-playbook.md`](docs/04-incident-response-playbook.md))*

---

## 💼 Key Skills & Core Competencies Demonstrated

- **Security Information & Event Management (SIEM)**: Architecture, agent enrollment, log indexing, and dashboard administration.
- **Detection Engineering**: Authoring custom XML correlation rules and aligning threat indicators with the MITRE ATT&CK matrix.
- **Endpoint Detection & Response (EDR / XDR)**: Linux kernel telemetry (`auditd`), File Integrity Monitoring (FIM), and syslog log aggregation.
- **Adversary Emulation**: Realistic attack simulations (credential spraying, privilege escalation, defense evasion).
- **Security Operations & Incident Response**: Incident triage, root-cause analysis, and containment playbooks aligned with NIST standards.
- **Systems Administration & Optimization**: Headless Linux management, JVM tuning, and hypervisor resource allocation.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE) — feel free to use, adapt, and build upon this lab for learning and research.
