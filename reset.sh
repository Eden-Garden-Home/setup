#!/bin/bash
echo "🧹 Pulizia completa dell'ambiente..."

# Ferma e rimuovi tutti i container del progetto
docker compose -f docker-compose-main.yml down -v 2>/dev/null || true

# Rimuovi tutti i volumi del progetto
docker volume rm $(docker volume ls -q | grep setup) 2>/dev/null || true

# Rimuovi tutte le reti del progetto
docker network rm $(docker network ls -q | grep setup) 2>/dev/null || true

# Rimuovi container orfani
docker container prune -f

# Rimuovi volumi orfani
docker volume prune -f

echo "✅ Pulizia completata!"
echo ""
echo "Per iniziare da capo, esegui:"
echo "  ./setup.sh"
