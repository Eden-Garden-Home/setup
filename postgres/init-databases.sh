#!/bin/bash
set -e
set -u

echo "🔧 Inizializzazione database multipli..."

# Funzione per creare database e utente
function create_user_and_database() {
    local database=$1
    local user=$2
    local password=$3
    
    echo "  📦 Creazione database '$database' con utente '$user'"
    
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE USER $user WITH ENCRYPTED PASSWORD '$password';
        CREATE DATABASE $database OWNER $user;
        GRANT ALL PRIVILEGES ON DATABASE $database TO $user;
EOSQL
}

# Crea database Authentik
if [ -n "${AUTHENTIK_DB_USER:-}" ] && [ -n "${AUTHENTIK_DB_PASSWORD:-}" ]; then
    create_user_and_database "${AUTHENTIK_DB_NAME:-authentik}" "${AUTHENTIK_DB_USER}" "${AUTHENTIK_DB_PASSWORD}"
fi

# Crea database n8n
if [ -n "${N8N_DB_USER:-}" ] && [ -n "${N8N_DB_PASSWORD:-}" ]; then
    create_user_and_database "${N8N_DB_NAME:-n8n}" "${N8N_DB_USER}" "${N8N_DB_PASSWORD}"
fi

echo "✅ Database inizializzati con successo!"
