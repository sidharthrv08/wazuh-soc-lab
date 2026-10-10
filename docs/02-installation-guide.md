# Step-by-Step Installation & Deployment Guide

This guide walks you through deploying the Wazuh SIEM Server and enrolling your Kali Linux VM as an endpoint in Oracle VM VirtualBox without writing any Python code.

---

## Part 1: VirtualBox Network Configuration

For the Wazuh Server and Kali Linux VM to communicate with each other and allow your host browser to access the dashboard:

### Option A: VirtualBox NAT Network (Recommended)
1. Open VirtualBox -> **File** -> **Tools** -> **Network Manager** -> **NAT Networks**.
2. Click **Create** (name it `SOCNet` or use the default `NatNetwork`).
3. Set IPv4 Prefix: `192.168.100.0/24` and ensure **Enable DHCP** is checked.
4. On both VMs (**Wazuh Server** and **Kali Linux**):
   - Go to **Settings** -> **Network** -> **Adapter 1**.
   - Attached to: **NAT Network**.
   - Name: `SOCNet`.

### Option B: Bridged Adapter
- If your home Wi-Fi/router permits device-to-device communication, set **Adapter 1** on both VMs to **Bridged Adapter** (select your Wi-Fi/Ethernet card). Both VMs will receive an IP directly from your home router.

---

## Part 2: Deploying the Wazuh SIEM Server

### 1. VM Creation (Ubuntu 22.04 LTS Server)
1. Download **Ubuntu Server 22.04 LTS ISO** (or use Wazuh OVA if downloaded).
2. Create a new VirtualBox VM:
   - **Name**: `Wazuh-SIEM-Server`
   - **Type**: Linux | **Version**: Ubuntu (64-bit)
   - **Base Memory**: `3072 MB` (or `2560 MB` for tighter setups)
   - **Processors**: `2 CPUs`
   - **Disk Size**: `25 GB`
3. Complete the standard Ubuntu server installation.

### 2. Low-Memory Optimization (Important for 6–8 GB Host Systems)
Once Ubuntu Server is installed, open the console and create a swapfile:
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 3. Run the Wazuh All-in-One Automated Installer
Execute the official bash installation script:
```bash
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

> [!NOTE]
> The installation takes ~5 to 10 minutes. When complete, the terminal displays:
> - Web URL: `https://<WAZUH_SERVER_IP>`
> - Username: `admin`
> - Generated Password: `<YOUR_AUTO_GENERATED_PASSWORD>`
> **Copy down this password immediately!**

### 4. Adjust Indexer JVM Memory (Optional, for smooth performance)
```bash
sudo sed -i 's/-Xms1g/-Xms512m/g' /etc/wazuh-indexer/jvm.options
sudo sed -i 's/-Xmx1g/-Xmx1g/g' /etc/wazuh-indexer/jvm.options
sudo systemctl restart wazuh-indexer
```

### 5. Access the Wazuh Dashboard
Open your host browser (Chrome, Edge, Firefox) and navigate to:
```text
https://<WAZUH_SERVER_IP>
```
Accept the self-signed certificate warning and log in with your credentials.

---

## Part 3: Enrolling the Kali Linux Endpoint

### 1. Check Kali Linux VM Network
In Kali Linux, verify you have network connectivity to the Wazuh Server:
```bash
ping -c 3 <WAZUH_SERVER_IP>
```

### 2. Install Wazuh Agent using the Setup Script
From this repository, copy `scripts/install-agent.sh` to your Kali VM, or execute:
```bash
sudo bash install-agent.sh <WAZUH_SERVER_IP>
```
Alternatively, run the manual commands:
```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee -a /etc/apt/sources.list.d/wazuh.list
sudo apt-get update -y
sudo WAZUH_MANAGER="<WAZUH_SERVER_IP>" apt-get install -y wazuh-agent
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl restart wazuh-agent
```

### 3. Verify Agent Registration
On Kali Linux:
```bash
sudo systemctl status wazuh-agent
```
On the Wazuh Web Dashboard:
- Navigate to **Endpoints Summary**.
- Your Kali Linux VM will appear with Status: **Active**!

---

## Part 4: Configuring Auditd Telemetry & Custom Rules

### 1. Install Audit Rules on Kali Linux
Copy `configs/audit.rules` to Kali Linux:
```bash
sudo cp audit.rules /etc/audit/rules.d/wazuh-soc.rules
sudo augenrules --load
sudo systemctl restart auditd
```

### 2. Deploy Custom Rules on Wazuh Server
On the Wazuh Server VM:
1. Open the custom rules file:
   ```bash
   sudo nano /var/ossec/etc/rules/local_rules.xml
   ```
2. Paste the contents of `configs/local_rules.xml`.
3. Restart the Wazuh Manager to apply rules:
   ```bash
   sudo systemctl restart wazuh-manager
   ```
