#!/bin/bash
# Stop all Claude Context infrastructure services

set -e

echo "🛑 Stopping Claude Context Infrastructure"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "Stopping Ollama..."
docker compose -f docker-compose.ollama.yml down

echo "Stopping Milvus stack..."
docker compose -f docker-compose.milvus.yml down

echo ""
echo "✅ All services stopped"
echo ""
echo "Note: Data is preserved in ./data/"
echo "To remove all data, run: ./scripts/clean.sh"
