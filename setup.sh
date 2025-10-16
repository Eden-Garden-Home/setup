#!/bin/bash
set -e

echo "🚀 Setup Infrastructure as Code"
echo "================================"
echo ""

# Verifica prerequisiti
if ! command -v docker &> /dev/null; then
    echo "❌ Docker non installato"
    exit 1
fi

if [ ! -f .env ]; then
    echo "❌ File .env non trovato"
    exit 1
fi

# Carica variabili
source .env

echo "📋 Configurazione:"
echo "  - Tailscale Hostname: ${TAILSCALE_HOSTNAME}"
echo "  - Tailscale Domain: ${TAILSCALE_DOMAIN}"
echo ""

# Verifica che le password siano state cambiate
if [[ "${POSTGRES_ROOT_PASSWORD}" == *"change_this"* ]]; then
    echo "⚠️  ATTENZIONE: Cambia le password in .env prima di continuare!"
    exit 1
fi

echo "1️⃣  Fermata stack esistente..."
docker compose -f docker-compose-main.yml down 2>/dev/null || true

echo ""
echo "2️⃣  Avvio stack..."
docker compose -f docker-compose-main.yml up -d

echo ""
echo "3️⃣  Attesa servizi..."
sleep 15

echo ""
echo "4️⃣  Verifica stato:"
docker compose -f docker-compose-main.yml ps

echo ""
echo "✅ Deploy completato!"
echo ""
echo "📌 Accedi ai servizi:"
echo "  - Traefik Dashboard: https://traefik.${TAILSCALE_DOMAIN}"
echo "  - Authentik: https://auth.${TAILSCALE_DOMAIN}"
echo "  - n8n: https://n8n.${TAILSCALE_DOMAIN}"
echo ""
echo "🔍 Monitora i log con:"
echo "  docker compose -f docker-compose-main.yml logs -f"
