#!/bin/bash
set -e

echo "🚀 Deploy Stack"
echo "==============="

# Crea directory
mkdir -p traefik

# Genera password se mancano
if grep -q "YOUR_" .env; then
    echo "⚠️  Genera password prima!"
    echo ""
    echo "PostgreSQL:"
    openssl rand -base64 32
    echo ""
    echo "Authentik Secret (50+ chars):"
    openssl rand -base64 64 | tr -d '\n' && echo
    echo ""
    echo "Authentik DB:"
    openssl rand -base64 32
    echo ""
    echo "n8n DB:"
    openssl rand -base64 32
    echo ""
    echo "n8n Encryption:"
    openssl rand -base64 32
    exit 1
fi

# Deploy
docker compose up -d

echo ""
echo "✅ Stack avviato!"
echo ""
echo "📌 Accedi tramite Tailscale a:"
echo "  - Traefik: https://traefik.edengarden.cc"
echo "  - Authentik: https://auth.edengarden.cc"
echo "  - n8n: https://n8n.edengarden.cc"
echo ""
echo "📍 Ricorda di configurare DNS:"
echo "  *.edengarden.cc → IP del server"
