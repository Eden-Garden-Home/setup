# Proxmox Server Architecture Setup

This guide describes step-by-step how to deploy a secure and segmented server infrastructure using Proxmox VE for virtualization and Docker Compose for service orchestration. The deployment includes VMs, containerized services (Traefik, Cloudflared, Authentik, n8n, PostgreSQL), with proper network isolation and configuration.

***

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Install Proxmox VE](#install-proxmox-ve)
3. [Create Virtual Machines (VMs)](#create-virtual-machines-vms)
4. [Network Configuration \& Segmentation](#network-configuration-&-segmentation)
5. [Install Docker \& Docker Compose](#install-docker--docker-compose)
***

## Prerequisites

- Physical server or capable VM host for Proxmox
- USB stick (at least 2GB) for Proxmox installation media
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


## Additional References

- Proxmox Documentation: https://pve.proxmox.com/wiki/Main_Page

