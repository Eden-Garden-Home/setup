<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Proxmox + Docker Compose Server Architecture Setup

This guide describes step-by-step how to deploy a secure and segmented server infrastructure using Proxmox VE for virtualization and Docker Compose for service orchestration. The deployment includes VMs, containerized services (Traefik, Cloudflared, Authentik, n8n, PostgreSQL), with proper network isolation and configuration.

***

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Install Proxmox VE](#install-proxmox-ve)
3. [Create Virtual Machines (VMs)](#create-virtual-machines-vms)
4. [Network Configuration \& Segmentation](#network-configuration-&-segmentation)
5. [Install Docker \& Docker Compose](#install-docker--docker-compose)
6. [Setup Docker Compose Services](#setup-docker-compose-services)
7. [Container Networking \& Service Isolation](#container-networking--service-isolation)
8. [Install and Configure Tailscale (optional)](#install-and-configure-tailscale-optional)
9. [Security Considerations](#security-considerations)
10. [Maintenance \& Troubleshooting](#maintenance--troubleshooting)
***

## Prerequisites

- Physical server or capable VM host for Proxmox
- USB stick (at least 2GB) for Proxmox installation media
- Reliable internet connection
- Knowledge of basic Linux CLI operations
- Domain name(s) for service exposure
***

## Install Proxmox VE

1. **Download the latest Proxmox VE ISO** from the official website: https://www.proxmox.com/en/downloads
2. **Flash the ISO to USB** (on Linux):

```bash
dd if=proxmox-ve_*.iso of=/dev/sdX bs=4M status=progress
```

Replace `/dev/sdX` with your actual USB device (find it via `lsblk`).
3. **Boot the server from USB**:
    - Enter the BIOS/UEFI and set USB as the first boot device.
    - Start the installer, choose "Install Proxmox VE."
    - Select target disk, set root password and management email.
    - Configure hostname and *at least one* static IP address for management.
    - Complete installation and reboot. Remove the USB stick.
4. **Access Web Console**: Navigate to `https://<SERVER_IP>:8006` from another machine.

***

## Create Virtual Machines (VMs)

1. **Login to the Proxmox web interface** as root.
2. For each VM you wish to create:
    - Go to "Create VM" in the left sidebar.
    - Assign a clear name (suggested: `docker-compose`, `splunk-search-head`, `splunk-indexer`).
    - Select an OS ISO (recommended: Ubuntu Server 22.04 LTS or Debian 12).
    - Specify CPU cores, RAM (minimum 2GB, preferably 4GB+ for Docker VM), and disk size (minimum 20GB, depend on usage).
    - Choose networking (`vmbr0` bridge for general use; advanced: add bridges for isolation).
    - Finish the wizard and start the VM.
3. **Install Ubuntu or Debian** on each VM following the distribution prompts.

***

## Network Configuration \& Segmentation

- **Default Network**: Proxmox creates `vmbr0` for general use.
- **Advanced Segmentation**:
    - If you want network isolation, create extra `vmbr1`, `vmbr2` bridges for dedicated networks between VMs (in Datacenter → Node → Network → Create → Linux Bridge).
    - Assign each VM a static IP either during OS installation or via `/etc/netplan/` (Ubuntu) or `/etc/network/interfaces` (Debian).
    - Example netplan config (Ubuntu):

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: no
      addresses: [192.168.41.10/24]
      gateway4: 192.168.41.1
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]
```

Apply those with `sudo netplan apply`.
- **Firewall/Security**:
    - Configure Proxmox firewall (Datacenter → Firewall, or Node → Firewall) to restrict traffic between VMs and expose only essential ports to outside.

***

## Install Docker \& Docker Compose

**On the Docker VM (recommended: Ubuntu):**

### Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```


### Install Docker (Official Method)

```bash
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo systemctl enable docker && sudo systemctl start docker
```


### Install Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```


***

## Setup Docker Compose Services

1. **Create a main project directory** for deployments:

```bash
mkdir ~/compose-services && cd ~/compose-services
```

2. **Create subfolders for data/config if needed:**

```bash
mkdir traefik cloudflared n8n postgres authentik
```

3. **Create a `.env` file** to hold secrets and configuration:

```env
DOMAIN_NAME=yourdomain.com
CF_TUNNEL_TOKEN=your_cloudflare_token
N8N_BASIC_AUTH_USER=youruser
N8N_BASIC_AUTH_PASSWORD=yourpass
POSTGRES_USER=n8n
POSTGRES_PASSWORD=your_db_password
POSTGRES_DB=n8n
AUTHENTIK_SECRET_KEY=your_secret_key
AUTHENTIK_POSTGRES_PASSWORD=your_authentik_db_pw
```

4. **Create your `docker-compose.yml`:** (example for all service containers)

```yaml
version: '3.8'
services:
  traefik:
    image: traefik:v2.10
    ... # Mount traefik.toml, configure entrypoints, certs, dashboard
  cloudflared:
    image: cloudflare/cloudflared:latest
    command: tunnel run --token $CF_TUNNEL_TOKEN
    ... # Environment variables, persistent volume if needed
  n8n:
    image: n8nio/n8n:latest
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      ...
    volumes:
      - ./n8n:/home/node/.n8n
    depends_on:
      - postgres
  postgres:
    image: postgres:15
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - ./postgres:/var/lib/postgresql/data
  authentik:
    image: ghcr.io/goauthentik/server:latest
    environment:
      - AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}
      - AUTHENTIK_POSTGRES_PASSWORD=${AUTHENTIK_POSTGRES_PASSWORD}
    depends_on:
      - authentik-postgresql
    ... # Add further configuration as needed
networks:
  traefik:
    driver: bridge
  backend:
    driver: bridge
```

5. **Add custom Traefik configuration for entrypoints and authentication integration.**
6. **Run the services:**

```bash
docker-compose up -d
```

7. **Verify Logs \& Access:**

```bash
docker ps
docker logs traefik --tail 100
docker logs n8n --tail 100
docker logs authentik --tail 100
docker logs cloudflared --tail 100
```


***

## Container Networking \& Service Isolation

- **Define Docker networks** in `docker-compose.yml` (as above). Assign each service only to necessary network(s).
- **Isolate backend services:** For example, Postgres should *only* be accessible by n8n and Authentik containers.
- **Traefik and Cloudflared** should be on same frontend network.
- **Expose only needed ports** (8080, 443, etc.) on Traefik. Other services should not expose ports to host unless necessary.
- **Example:**

```yaml
networks:
  traefik:
    driver: bridge
  backend:
    driver: bridge
services:
  traefik:
    networks:
      - traefik
  cloudflared:
    networks:
      - traefik
  n8n:
    networks:
      - backend
  postgres:
    networks:
      - backend
```


***

## Install and Configure Tailscale (optional)

On each VM where secure VPN access is desired:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey <your_auth_key>
```

- Configure ACLs and routing rules in the Tailscale admin panel for service access restrictions.

***

## Security Considerations

- **Restrict firewall rules:** Only allow ports required for management (8006), ingress (80/443), VPN (Tailscale), and intra-VM communication as needed.
- **Set up automatic updates:** On all VMs, enable or schedule security updates.
- **Rotate credentials regularly:** For environment secrets, service credentials, and API keys.
- **Backup data volumes:** Especially for databases (`postgres`, `authentik`). Use Proxmox snapshot \& rsync/db-dump for redundancy.
- **Use HTTPS for all exposed services:** Enable TLS via Traefik and Cloudflare tunnel.
- **Monitor container health:** Set up alerts or monitoring stack as best fits your needs (Prometheus, etc.)

***

## Maintenance \& Troubleshooting

- **Restart services:**

```bash
docker-compose restart <service_name>
```

- **Stop and remove all containers:**

```bash
docker-compose down
```

- **Update images:**

```bash
docker-compose pull
docker-compose up -d --force-recreate
```

- **Check system status:**
    - Resource usage: `htop`, `docker stats`
    - Disk usage: `df -h`
- **Proxmox backups:**
    - Schedule regular VM snapshots/backups via Proxmox UI.

***

## Additional References

- Proxmox Documentation: https://pve.proxmox.com/wiki/Main_Page
- Docker Docs: https://docs.docker.com/
- Docker Compose Docs: https://docs.docker.com/compose/
- Traefik Docs: https://doc.traefik.io/traefik/
- Cloudflared Docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- Authentik Docs: https://goauthentik.io/docs/
- n8n Docs: https://docs.n8n.io/
- Tailscale Docs: https://tailscale.com/kb/

***

This guide covers the full setup of the Proxmox-based virtual infrastructure, container service deployment, internal and public network configuration for secure service orchestration. Modify configuration samples and credentials to suit your specific requirements and security policies.

