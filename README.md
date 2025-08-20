# **Home Docker Build & AI Integration**

This repository contains a complete **Docker-based home server setup** for running **Nextcloud**, **AI services** (OpenWebUI + Ollama DeepSeek), and other containers with secure, private remote access via **Tailscale**.

---

## **Table of Contents**
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Disk Setup](#disk-setup)
    - [What `setup-disk.sh` Does](#what-setup-disksh-does)
4. [Tailscale Setup](#tailscale-setup)
5. [Docker Services](#docker-services)
    - [Nextcloud Stack](#nextcloud-stack)
    - [OpenWebUI + Ollama DeepSeek](#openwebui--ollama-deepseek)
6. [Starting the Environment](#starting-the-environment)
7. [Connectivity & Troubleshooting](#connectivity--troubleshooting)
8. [Future Plans](#future-plans)

---

## **Overview**
This setup provides:
- A **self-hosted environment** with secure, private networking via **Tailscale**.
- **Nextcloud** for storage, file syncing, and collaboration.
- **AI services** powered by **OpenWebUI** and **Ollama DeepSeek**.
- Automated disk setup with **RAID support** for redundancy.

---

## **Prerequisites**
Before starting, ensure you have:

- **Docker Installed** → [Get Docker](https://docs.docker.com/get-docker/)
- **Tailscale Installed** → [Get Tailscale](https://tailscale.com/download)
- **Two SSDs** (same size recommended; RAID 1 halves effective capacity)
- Create an empty `.env` file in the repository root for storing sensitive credentials.

---

## **Disk Setup**
The `setup-disk.sh` script **must be executed before bringing up Docker**.  
This prepares a secure, redundant storage environment for Nextcloud and other services.

### **Steps**
1. Identify available disks:
   ```bash
   lsblk
   ```
2. Run the setup script:
   ```bash
   sudo bash setup-disk.sh
   ```
3. Back up the generated **disk encryption key** (to be added in future).

---

### **What `setup-disk.sh` Does**
The script automates secure disk preparation:

1. **Detects Two Disks**  
   Uses `lsblk` to identify available drives.

2. **Creates a RAID 1 Array** *(Mirrored Disks)*  
   Uses `mdadm` to combine both SSDs into a redundant array.

3. **Encrypts the RAID Volume**  
   Uses **LUKS encryption** to secure your data at rest.

4. **Formats the Filesystem**  
   Prepares the volume using `ext4` (or similar), optimized for Docker workloads.

5. **Mounts Secure Storage**  
   Mounts the encrypted volume at:
   ```
   /mnt/secure_data
   ```
   This directory is used by:
   - **Nextcloud** → `/mnt/secure_data/nextcloud`
   - **MariaDB** → `/mnt/secure_data/mysql`
   - **AI Models** (optional)

6. **Sets Up Persistent Mounts**  
   Updates `/etc/fstab` so the encrypted volume auto-mounts at boot.

> ⚠️ **Important:**  
   This script **wipes both SSDs**. Ensure you back up data before running it.

---

## **Tailscale Setup**
Instead of exposing services publicly, this stack uses **Tailscale** for secure private networking.

### **1. Install Tailscale**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### **2. Authenticate the Node**
```bash
sudo tailscale up
```
Log in via your browser when prompted.

### **3. Access Services Securely**
Once connected, access all services via the server’s **Tailscale IP**.

---

## **Docker Services**

### **Nextcloud Stack**
Includes:
- **MariaDB** → Database
- **Nextcloud** → Personal file storage
- **Tailscale** → Secure private access

**Persistent Data Locations:**
```
/mnt/secure_data/mysql     → MariaDB data
/mnt/secure_data/nextcloud → Nextcloud data
```

**Startup Order:**
1. MariaDB  
2. Nextcloud  
3. Tailscale-enabled services  

**Environment Variables** (`.env`):
```bash
MYSQL_ROOT_PASSWORD=<root_password>
MYSQL_PASSWORD=<nextcloud_db_password>
NEXTCLOUD_ADMIN_USER=<admin_user>
NEXTCLOUD_ADMIN_PASSWORD=<admin_password>
NEXTCLOUD_TRUSTED_DOMAINS=<your.tailscale.ip>
```

---

### **OpenWebUI + Ollama DeepSeek**
AI-powered services for running and interacting with models.

#### **OpenWebUI**
- Web interface to manage and chat with models.
- Accessible on **port 8333**.
- Configurations stored in `./open-webui`.

#### **Ollama DeepSeek**
- Hosts AI models and integrates with OpenWebUI.

#### **Environment Variables**
```bash
OLLAMA_HOST=0.0.0.0
OLLAMA_PORT=8080
OLLAMA_BASE_URL=ollamadeepseek
```

#### **How It Works**
1. **Ollama DeepSeek** → Serves AI models.
2. **OpenWebUI** → Provides a web interface.
3. Communication → Uses **JSON-RPC** over **port 8080**.

---

## **Starting the Environment**
From the repository root:
```bash
sudo docker compose up -d
```
Check container statuses:
```bash
sudo docker ps
```

---

## **Connectivity & Troubleshooting**

- **Check logs:**
   ```bash
   sudo docker logs <service_name>
   ```
- **Verify key ports:**
    - OpenWebUI → `8333`
    - Ollama → `8080`
    - Nextcloud → defined in `docker-compose.yml`
- **Tailscale issues:**
   ```bash
   tailscale status
   sudo systemctl restart tailscaled
   ```

---

## **Future Plans**
- Multi-factor authentication for sensitive apps.
- Automated backups for Nextcloud & AI models.
- Grafana + Prometheus monitoring.
- Possible multi-node Tailscale deployments.