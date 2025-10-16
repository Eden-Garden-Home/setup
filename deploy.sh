#!/bin/bash
set -e

echo "🚀 Deploy Stack Edengarden"
echo "=========================="

# Crea directory
mkdir -p traefik

# Verifica password
if grep -q "cambia_con" .env; then
    echo ""
    echo "⚠️  GENERA PASSWORD PRIMA DI CONTINUARE!"
    echo ""
    echo "PostgreSQL (32 chars):"
    openssl rand -base64 32
    echo ""
    echo "Authentik Secret (50+ chars):"
    openssl rand -base64 64 | tr -d '\n' && echo
    echo ""
    echo "Authentik DB (32 chars):"
    openssl rand -base64 32
    echo ""
    echo "n8n DB (32 chars):"
    openssl rand -base64 32
    echo ""
    echo "n8n Encryption (32 chars):"
    openssl rand -base64 32
    echo ""
    echo "Copia queste password nel file .env e rilancia ./deploy.sh"
    exit 1
fi

# Crea database Authentik e n8n
echo "📦 Preparazione database..."
docker compose up -d postgresql
sleep 5

docker compose exec -T postgresql psql -U postgres <<-EOSQL
    CREATE DATABASE authentik;
    CREATE DATABASE n8n;
    CREATE USER authentik WITH ENCRYPTED PASSWORD '${AUTHENTIK_DB_PASSWORD}';
    CREATE USER n8n WITH ENCRYPTED PASSWORD '${N8N_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE authentik TO authentik;
    GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
EOSQL

echo ""
echo "🚀 Avvio stack completo..."
docker compose up -d

echo ""
echo "⏳ Attesa 10 secondi..."
sleep 10

echo ""
echo "✅ Stack avviato!"
echo ""
echo "📌 Accedi (da dispositivo Tailscale):"
echo "  - Authentik: https://server-edengarden.zebra-wezen.ts.net"
echo "  - n8n: https://server-edengarden.zebra-wezen.ts.net/n8n"
echo "  - Traefik: https://server-edengarden.zebra-wezen.ts.net/dashboard/"
echo ""
echo "🔍 Monitora: docker compose logs -f"
