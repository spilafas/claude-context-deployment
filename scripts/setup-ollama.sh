#!/bin/bash
# Setup Ollama with embedding model

set -e

echo "🤖 Setting up Ollama Embedding Model"
echo "====================================="
echo ""

# Default model
MODEL="${1:-nomic-embed-text}"

echo "Pulling embedding model: $MODEL"
echo "This may take a few minutes depending on your internet connection..."
echo ""

docker exec ollama ollama pull "$MODEL"

echo ""
echo "✅ Model $MODEL downloaded successfully!"
echo ""
echo "Testing embedding generation..."
RESPONSE=$(curl -s http://localhost:11434/api/embeddings -d "{
  \"model\": \"$MODEL\",
  \"prompt\": \"Hello, world!\"
}")

if echo "$RESPONSE" | grep -q "embedding"; then
  echo "✅ Embedding generation test successful!"
  echo ""
  echo "Available models:"
  docker exec ollama ollama list
else
  echo "❌ Embedding generation test failed"
  echo "Response: $RESPONSE"
  exit 1
fi

echo ""
echo "Ollama is ready to use!"
echo "Model: $MODEL"
echo "API endpoint: http://localhost:11434"
