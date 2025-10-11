# Guida Implementazione Architettura Server Proxmox

## Panoramica
Questa guida ti accompagnerà nella creazione di un'architettura sicura e segregata per il tuo server Proxmox, seguendo le best practice per la sicurezza e l'isolamento dei servizi.

## Prerequisiti

### 1. Server Proxmox
- Proxmox VE installato e configurato
- Almeno 16GB RAM e 4 CPU cores
- Accesso SSH al server

### 2. Account e Servizi Esterni
- Account Cloudflare con dominio configurato
- Account Tailscale
- Certificati SSL (Let's Encrypt tramite Cloudflare)

### 3. Conoscenze Richieste
- Conoscenza base di Docker e Docker Compose
- Familiarità con Proxmox
- Conoscenze di base di networking

## Fase 1: Preparazione VM su Proxmox

### 1.1 Creazione VM Docker Host
```bash
# Crea una VM con almeno:
# - 8GB RAM
# - 4 vCPU
# - 100GB storage
# - Ubuntu Server 22.04 LTS

# Nel pannello Proxmox, crea la VM e configura:
# - Network: vmbr0 (o bridge dedicato)
# - Enable VLAN aware se usi VLANs
```

### 1.2 Installazione Docker nella VM
```bash
# SSH nella VM e installa Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Aggiungi utente al gruppo docker
sudo usermod -aG docker $USER

# Installa Docker Compose
sudo apt update
sudo apt install docker-compose-plugin

# Verifica installazione
docker --version
docker compose version
```

### 1.3 Configurazione Network Segregation
```bash
# Esegui lo script per creare le reti Docker
chmod +x create-networks.sh
./create-networks.sh
```

## Fase 2: Configurazione Servizi Esterni

### 2.1 Cloudflare Setup
1. Vai su Cloudflare Dashboard
2. Aggiungi il tuo dominio se non presente
3. Vai su "Zero Trust" > "Tunnels"
4. Crea un nuovo Tunnel:
   - Nome: `server-proxmox-tunnel`
   - Copia il token generato
5. Crea record DNS:
   - `A` record: `webhooks.tuodominio.com` → Tunnel
   - `CNAME` record: `*.ts.tuodominio.com` → `nome-tailnet.ts.net`

### 2.2 Tailscale Setup
1. Vai su Tailscale Admin Console
2. Settings > Keys > Generate auth key
3. Configura:
   - Reusable: ✓
   - Expires: mai (o 1 anno)
   - Devices: qualsiasi
4. Copia la chiave generata

### 2.3 API Keys
```bash
# Cloudflare API Token (Zone:DNS:Edit permissions)
# Vai su: https://dash.cloudflare.com/profile/api-tokens
# Crea token con permessi: Zone:DNS:Edit per il tuo dominio
```

## Fase 3: Deployment dei Servizi

### 3.1 Configurazione Environment
```bash
# Copia e modifica il file .env
cp .env.example .env
nano .env

# Compila tutti i valori richiesti:
# - Domini e subdominali
# - Token API di Cloudflare e Tailscale
# - Password forti per database
# - Chiavi di encryption casuali
```

### 3.2 Generazione Chiavi e Segreti
```bash
# Genera chiavi sicure
openssl rand -base64 32  # Per AUTHENTIK_SECRET_KEY
openssl rand -base64 32  # Per N8N_ENCRYPTION_KEY
openssl rand -base64 20  # Per password database
```

### 3.3 Deploy Servizi Core
```bash
# Avvia i servizi principali
docker compose -f docker-compose-main.yml up -d

# Verifica che tutti i servizi siano attivi
docker compose -f docker-compose-main.yml ps

# Controlla i log se ci sono problemi
docker compose -f docker-compose-main.yml logs -f
```

### 3.4 Deploy Servizi Applicativi
```bash
# Attendi che i servizi core siano completamente avviati (2-3 minuti)
# Poi avvia i servizi applicativi
docker compose -f docker-compose-services.yml up -d

# Verifica stato
docker compose -f docker-compose-services.yml ps
```

## Fase 4: Configurazione Authentik

### 4.1 Setup Iniziale
1. Connettiti a Tailscale dal tuo dispositivo
2. Vai su `https://auth.nome-tailnet.ts.net`
3. Completa il setup iniziale di Authentik
4. Crea utente admin

### 4.2 Configurazione Forward Auth
1. Nel panel admin di Authentik:
   - Applications > Providers > Create
   - Type: "Forward auth (single application)"
   - External host: `https://servizio.nome-tailnet.ts.net`
2. Crea applicazione collegata al provider
3. Ripeti per ogni servizio che vuoi proteggere

## Fase 5: Test e Verifica

### 5.1 Test Accesso via Tailscale
```bash
# Testa tutti gli endpoint protetti:
# https://traefik.nome-tailnet.ts.net (dashboard Traefik)
# https://auth.nome-tailnet.ts.net (Authentik)
# https://n8n.nome-tailnet.ts.net (n8n interface)
# https://1password.nome-tailnet.ts.net (1Password Connect)
```

### 5.2 Test Webhook via Cloudflare
```bash
# Testa l'endpoint webhook (senza VPN):
curl -X POST https://webhooks.tuodominio.com/webhook/test   -H "Content-Type: application/json"   -d '{"test": "data"}'
```

### 5.3 Verifica Isolamento Network
```bash
# Verifica che i container non possano comunicare tra reti diverse
docker exec traefik ping authentik-server  # dovrebbe funzionare
docker exec n8n ping redis  # dovrebbe fallire (reti diverse)
```

## Fase 6: Sicurezza e Hardening

### 6.1 Firewall VM
```bash
# Configura UFW nella VM
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 6.2 Backup Strategy
```bash
# Script backup database
#!/bin/bash
docker exec postgresql pg_dumpall -U postgres > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup volumi Docker
docker run --rm -v postgresql-data:/data -v $(pwd):/backup alpine   tar czf /backup/postgresql-data_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

### 6.3 Monitoraggio
```bash
# Aggiungi monitoring dei container
docker stats

```

## Fase 7: Manutenzione

### 7.1 Update Procedure
```bash
# Update immagini Docker
docker compose -f docker-compose-main.yml pull
docker compose -f docker-compose-services.yml pull

# Restart con nuove immagini
docker compose -f docker-compose-main.yml up -d
docker compose -f docker-compose-services.yml up -d

# Cleanup immagini vecchie
docker image prune -f
```

### 7.2 Backup Automatico
```bash
# Aggiungi a crontab
0 2 * * * /home/user/backup-script.sh
```

## Troubleshooting Comune

### Problema: Servizi non raggiungibili via Tailscale
**Soluzione:**
1. Verifica che Tailscale container sia running
2. Controlla che il dispositivo sia approvato in Tailscale Admin
3. Verifica DNS resolution: `nslookup servizio.nome-tailnet.ts.net`

### Problema: Webhook non funzionano
**Soluzione:**
1. Verifica tunnel Cloudflare attivo
2. Controlla DNS record: `webhooks.tuodominio.com`
3. Test diretto: `curl -I https://webhooks.tuodominio.com`

### Problema: Authentik non autentica
**Soluzione:**
1. Verifica configurazione Forward Auth in Traefik
2. Controlla log Authentik: `docker logs authentik-server`
3. Verifica cookie domain nelle impostazioni Authentik

### Problema: Database connection failed
**Soluzione:**
1. Verifica che PostgreSQL sia healthy: `docker ps`
2. Test connessione: `docker exec postgresql pg_isready`
3. Controlla password in .env file

## Best Practices Implementate

### Sicurezza
- ✅ Network segregation con Docker networks
- ✅ Traffico interno isolato (reti internal)
- ✅ Autenticazione centralizzata con Authentik
- ✅ TLS end-to-end con certificati automatici
- ✅ Accesso VPN-only per servizi sensibili
- ✅ Webhook dedicati senza autenticazione

### Isolamento
- ✅ Servizi separati per funzione
- ✅ Database isolati in rete dedicata
- ✅ Reverse proxy come unico entry point
- ✅ Container con privilegi minimi

### Monitoraggio
- ✅ Log centralizzati
- ✅ Health checks per tutti i servizi
- ✅ Metriche accessibili via Traefik dashboard

Questa architettura fornisce una base solida e sicura per i tuoi servizi, rispettando tutti i requisiti di sicurezza e segregazione che hai specificato.
