#!/bin/bash
# Clean all data and reset deployment

set -e

echo "⚠️  WARNING: This will delete all data!"
echo "========================================"
echo ""
echo "This will:"
echo "  - Stop all containers"
echo "  - Remove all Docker volumes and networks"
echo "  - Delete all data in ./data/"
echo ""
read -p "Are you sure? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo ""
echo "Stopping services..."
docker compose -f docker-compose.ollama.yml down -v
docker compose -f docker-compose.milvus.yml down -v

echo "Removing data directories..."
rm -rf data/milvus/*
rm -rf data/etcd/*
rm -rf data/minio/*
rm -rf data/ollama/*

echo "Removing Docker networks..."
docker network rm milvus-network 2>/dev/null || true
docker network rm ollama-network 2>/dev/null || true

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "To start fresh, run: ./scripts/start.sh"
