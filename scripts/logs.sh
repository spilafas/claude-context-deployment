#!/bin/bash
# View logs from Claude Context services

SERVICE="${1:-all}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

case "$SERVICE" in
  milvus)
    echo "📋 Milvus logs:"
    docker logs -f milvus-standalone
    ;;
  etcd)
    echo "📋 etcd logs:"
    docker logs -f milvus-etcd
    ;;
  minio)
    echo "📋 MinIO logs:"
    docker logs -f milvus-minio
    ;;
  ollama)
    echo "📋 Ollama logs:"
    docker logs -f ollama
    ;;
  all)
    echo "📋 All service logs (press Ctrl+C to exit):"
    docker compose -f docker-compose.milvus.yml logs -f &
    docker compose -f docker-compose.ollama.yml logs -f &
    wait
    ;;
  *)
    echo "Usage: $0 [service]"
    echo ""
    echo "Services:"
    echo "  milvus  - View Milvus logs"
    echo "  etcd    - View etcd logs"
    echo "  minio   - View MinIO logs"
    echo "  ollama  - View Ollama logs"
    echo "  all     - View all logs (default)"
    ;;
esac
