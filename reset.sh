#!/bin/bash
echo "🧹 Pulizia completa dell'ambiente..."

# Ferma TUTTI i container Docker in esecuzione
echo "🛑 Fermata tutti i container..."
docker stop $(docker ps -q) 2>/dev/null || true

# Rimuovi TUTTI i container
echo "🗑️  Rimozione tutti i container..."
docker rm $(docker ps -aq) 2>/dev/null || true

# Rimuovi tutti i volumi
echo "🗑️  Rimozione volumi..."
docker volume prune -af

# Rimuovi tutte le reti custom
echo "🌐 Rimozione reti..."
docker network prune -f

echo ""
echo "✅ Pulizia completata!"
echo ""
echo "🔍 Verifica porte libere:"
sudo lsof -i :80 2>/dev/null || echo "  ✅ Porta 80 libera"
sudo lsof -i :443 2>/dev/null || echo "  ✅ Porta 443 libera"
echo ""
echo "Per avviare lo stack, esegui:"
echo "  ./setup.sh"
