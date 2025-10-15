
#!/bin/bash

# Script per inizializzare i database necessari in PostgreSQL
# Esegui questo DOPO aver avviato il container PostgreSQL

echo "🗄️  Inizializzazione database PostgreSQL..."

# Connetti a PostgreSQL e crea i database necessari
docker-compose -f docker-compose-main.yml exec postgresql psql -U postgres <<-EOSQL
    -- Database e utente per Authentik
    CREATE USER authentik WITH PASSWORD '${AUTHENTIK_DB_PASSWORD}';
    CREATE DATABASE authentik OWNER authentik;
    GRANT ALL PRIVILEGES ON DATABASE authentik TO authentik;

    -- Database e utente per n8n
    CREATE USER n8n WITH PASSWORD '${N8N_DB_PASSWORD}';
    CREATE DATABASE n8n OWNER n8n;
    GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;

    -- Mostra i database creati
    \l
EOSQL

echo "✅ Database creati con successo!"
echo ""
echo "Database disponibili:"
echo "  - authentik (user: authentik)"
echo "  - n8n (user: n8n)"