#!/bin/bash
# Test Claude Context deployment end-to-end

set -e

echo "🧪 Testing Claude Context Deployment"
echo "====================================="
echo ""

FAILED=0

# Test 1: Check if containers are running
echo "Test 1: Checking container status..."
CONTAINERS=("milvus-standalone" "milvus-etcd" "milvus-minio" "ollama")
for container in "${CONTAINERS[@]}"; do
  if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "  ✅ $container is running"
  else
    echo "  ❌ $container is not running"
    FAILED=1
  fi
done

# Test 2: Check Milvus health
echo ""
echo "Test 2: Checking Milvus health..."
if curl -sf http://localhost:9091/healthz > /dev/null 2>&1; then
  echo "  ✅ Milvus health check passed"
else
  echo "  ❌ Milvus health check failed"
  FAILED=1
fi

# Test 3: Check Milvus gRPC endpoint
echo ""
echo "Test 3: Checking Milvus gRPC endpoint..."
if nc -z localhost 19530 2>/dev/null || timeout 1 bash -c 'cat < /dev/null > /dev/tcp/localhost/19530' 2>/dev/null; then
  echo "  ✅ Milvus gRPC port 19530 is accessible"
else
  echo "  ❌ Milvus gRPC port 19530 is not accessible"
  FAILED=1
fi

# Test 4: Check MinIO
echo ""
echo "Test 4: Checking MinIO..."
if curl -sf http://localhost:9000/minio/health/live > /dev/null 2>&1; then
  echo "  ✅ MinIO health check passed"
else
  echo "  ❌ MinIO health check failed"
  FAILED=1
fi

# Test 5: Check Ollama
echo ""
echo "Test 5: Checking Ollama API..."
if curl -sf http://localhost:11434/api/version > /dev/null 2>&1; then
  echo "  ✅ Ollama API is accessible"
  VERSION=$(curl -s http://localhost:11434/api/version | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
  echo "     Version: $VERSION"
else
  echo "  ❌ Ollama API is not accessible"
  FAILED=1
fi

# Test 6: Check if embedding model is available
echo ""
echo "Test 6: Checking embedding model..."
MODELS=$(docker exec ollama ollama list 2>/dev/null || echo "")
if echo "$MODELS" | grep -q "nomic-embed-text\|mxbai-embed-large\|all-minilm"; then
  echo "  ✅ Embedding model is installed"
  echo "$MODELS" | grep "embed" | sed 's/^/     /'
else
  echo "  ⚠️  No embedding model found"
  echo "     Run: ./scripts/setup-ollama.sh"
  FAILED=1
fi

# Test 7: Test embedding generation
echo ""
echo "Test 7: Testing embedding generation..."
EMBED_RESPONSE=$(curl -s http://localhost:11434/api/embeddings -d '{
  "model": "nomic-embed-text",
  "prompt": "test"
}' 2>/dev/null || echo "")

if echo "$EMBED_RESPONSE" | grep -q "embedding"; then
  echo "  ✅ Embedding generation successful"
  EMBED_DIM=$(echo "$EMBED_RESPONSE" | grep -o '"embedding":\[[^]]*\]' | tr ',' '\n' | wc -l | tr -d ' ')
  echo "     Embedding dimension: $EMBED_DIM"
else
  echo "  ❌ Embedding generation failed"
  if [ ! -z "$EMBED_RESPONSE" ]; then
    echo "     Response: $EMBED_RESPONSE"
  fi
  FAILED=1
fi

# Test 8: Check data persistence
echo ""
echo "Test 8: Checking data directories..."
DIRS=("data/milvus" "data/etcd" "data/minio" "data/ollama")
for dir in "${DIRS[@]}"; do
  if [ -d "../$dir" ] && [ "$(ls -A ../$dir 2>/dev/null)" ]; then
    echo "  ✅ $dir exists and contains data"
  else
    echo "  ⚠️  $dir is empty or doesn't exist"
  fi
done

# Summary
echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
  echo "✅ All tests passed!"
  echo ""
  echo "Your Claude Context deployment is ready!"
  echo ""
  echo "Next steps:"
  echo "  1. Configure Claude Code MCP (see README.md)"
  echo "  2. Restart Claude Code"
  echo "  3. Use 'index this codebase' in Claude Code"
else
  echo "❌ Some tests failed"
  echo ""
  echo "Troubleshooting:"
  echo "  - Check logs: ./scripts/logs.sh [service]"
  echo "  - Restart services: ./scripts/stop.sh && ./scripts/start.sh"
  echo "  - See README.md for detailed troubleshooting"
  exit 1
fi
