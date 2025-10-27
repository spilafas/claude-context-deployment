#!/bin/bash
# Start all Claude Context infrastructure services

set -e

echo "🚀 Starting Claude Context Self-Hosted Infrastructure"
echo "======================================================"
echo ""

# Change to the deployment directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Start Milvus stack
echo "📦 Starting Milvus stack (etcd, MinIO, Milvus)..."
docker compose -f docker-compose.milvus.yml up -d

# Wait for Milvus to be healthy
echo "⏳ Waiting for Milvus to be healthy (this may take 60-90 seconds)..."
for i in {1..30}; do
  if curl -sf http://localhost:9091/healthz > /dev/null 2>&1; then
    echo "✅ Milvus is healthy!"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Milvus health check timed out"
    echo "   Run 'docker logs milvus-standalone' to check logs"
    exit 1
  fi
  echo "   Attempt $i/30..."
  sleep 3
done

# Start Ollama
echo ""
echo "🤖 Starting Ollama..."
docker compose -f docker-compose.ollama.yml up -d

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama to be ready..."
for i in {1..10}; do
  if curl -sf http://localhost:11434/api/version > /dev/null 2>&1; then
    echo "✅ Ollama is ready!"
    break
  fi
  if [ $i -eq 10 ]; then
    echo "❌ Ollama health check timed out"
    exit 1
  fi
  sleep 2
done

echo ""
echo "✨ All services started successfully!"
echo ""
echo "Service Status:"
echo "  • Milvus:        http://localhost:19530 (gRPC)"
echo "  • Milvus Health: http://localhost:9091/healthz"
echo "  • MinIO Console: http://localhost:9001 (admin/minioadmin)"
echo "  • Ollama API:    http://localhost:11434"
echo ""
echo "Next steps:"
echo "  1. Pull embedding model: ./scripts/setup-ollama.sh"
echo "  2. Configure Claude Code MCP (see README.md)"
echo "  3. Test deployment: ./scripts/test-deployment.sh"
