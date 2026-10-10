# SOC Home Lab: Architecture & Design

## 1. Network Topology

The lab operates entirely within **Oracle VM VirtualBox**, isolating security testing traffic from external networks while allowing management access from the host OS.

```
+-------------------------------------------------------------------------------+
|                             HOST MACHINE (Windows)                            |
|                     Browser Management: https://192.168.100.10               |
+---------------------------------------+---------------------------------------+
                                        |
                 +----------------------+----------------------+
                 |                                             |
+----------------v--------------------+       +----------------v--------------------+
|        VM 1: WAZUH SIEM SERVER      |       |      VM 2: MONITORED ENDPOINT       |
|          (Ubuntu Server 22.04)      |       |            (Kali Linux)             |
|                                     |       |                                     |
|  - Wazuh Manager (Correlation/Rules)|       |  - Wazuh Agent (Telemetry Ingestion)|
|  - Wazuh Indexer (OpenSearch Engine)|<======|  - Audit Daemon (auditd execve)     |
|  - Wazuh Dashboard (HTTPS / Web UI) | Port  |  - Syscheck (File Integrity Monitor)|
|                                     | 1514  |  - Auth / Syslog Forwarding         |
|  IP: 192.168.100.10                 |       |  IP: 192.168.100.20                 |
+-------------------------------------+       +-------------------------------------+
                 |                                             |
                 +----------------------+----------------------+
                                        |
                        [ VirtualBox NatNetwork / Bridged ]
```

---

## 2. Port & Communication Matrix

| Service | Port | Protocol | Source | Destination | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Agent Enrollment** | 1515 | TCP | Kali Endpoint | Wazuh Server | Automatic registration of new agents via authd |
| **Agent Telemetry** | 1514 | TCP/UDP | Kali Endpoint | Wazuh Server | Encrypted secure message transport for events & logs |
| **Wazuh Dashboard** | 443 | TCP (HTTPS) | Host Browser | Wazuh Server | SOC Analyst visualization, alerting, and management |
| **Wazuh Indexer** | 9200 | TCP (HTTPS) | Wazuh Server (Internal) | Wazuh Server | Indexed document storage & search API (OpenSearch) |
| **SSH Service** | 22 | TCP | Kali / Host | Both VMs | Remote shell administration & brute-force testing |

---

## 3. Component Breakdown

### A. Wazuh SIEM Server
- **Wazuh Manager**: Ingests incoming log streams from agents, correlates events against the rule engine (`local_rules.xml`), evaluates anomalies, and fires alerts.
- **Wazuh Indexer**: Scalable search engine that indexes alerts and telemetry in JSON format.
- **Wazuh Dashboard**: Interactive graphical UI for exploring alerts, visualizing MITRE ATT&CK tactics, and monitoring system integrity.

### B. Monitored Endpoint (Kali Linux)
- **Wazuh Agent**: Lightweight C daemon consuming minimal CPU/RAM. Reads system logs, tracks process creation via `auditd`, and monitors file modifications.
- **Linux Audit Daemon (`auditd`)**: Captures kernel-level `execve` system calls, tracking executed commands, sudo privilege escalations, and binary tampering.
- **Syscheck (FIM)**: Generates SHA256 checksums of system files (`/etc/passwd`, `/etc/shadow`, `/bin`) and alerts upon modification.

---

## 4. Hardware Sizing & Memory Optimization

For systems running on **6 GB to 8 GB total RAM**:

| VM | Recommended RAM | Minimum RAM | vCPUs | Disk |
| :--- | :--- | :--- | :--- | :--- |
| **Wazuh Server** | 3072 MB (3 GB) | 2560 MB (2.5 GB) | 2 | 25 GB |
| **Kali Linux VM** | 2048 MB (2 GB) | 1536 MB (1.5 GB) | 1 | 20 GB |
| **Host OS (Windows)**| 2048–3072 MB | - | - | - |

> [!TIP]
> **Tuning Wazuh JVM for Low-Memory Systems**:
> Wazuh Indexer's default JVM heap can be tuned down for home labs by editing `/etc/wazuh-indexer/jvm.options`:
> ```text
> -Xms512m
> -Xmx1g
> ```
> Adding a 2 GB swap file on the Ubuntu Wazuh server prevents out-of-memory errors while keeping resource consumption light.
