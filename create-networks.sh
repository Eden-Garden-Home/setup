#!/bin/bash

# Creazione delle reti Docker per la segregazione
echo "Creazione reti Docker..."

# Rete pubblica per Traefik
docker network create traefik-public --driver bridge --subnet=172.20.0.0/16

# Rete interna per Authentik
docker network create authentik-internal --driver bridge --subnet=172.21.0.0/16 --internal

# Rete interna per i servizi
docker network create services-internal --driver bridge --subnet=172.22.0.0/16 --internal

# Rete interna per i database
docker network create database-internal --driver bridge --subnet=172.23.0.0/16 --internal

echo "Reti create con successo!"
echo ""
echo "Reti disponibili:"
docker network ls | grep -E "(traefik-public|authentik-internal|services-internal|database-internal)"
