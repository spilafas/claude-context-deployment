# Claude Context MCP - Self-Hosted Deployment

Complete self-hosted deployment of Claude Context MCP with local Milvus vector database and Ollama embeddings.

## Architecture

```
┌─────────────────┐
│  Claude Code    │
│   (MCP Client)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Claude Context MCP Server      │
│  (npx @zilliz/claude-context)   │
└────┬──────────────────────┬─────┘
     │                      │
     ▼                      ▼
┌─────────────┐      ┌──────────────┐
│   Milvus    │      │   Ollama     │
│  (Vectors)  │      │ (Embeddings) │
└─────────────┘      └──────────────┘
```

## System Requirements

### Minimum
- **CPU**: 4 cores (ARM64 or x86_64)
- **RAM**: 8 GB
- **Disk**: 20 GB free space
- **OS**: macOS, Linux, or Windows with WSL2

### Recommended
- **CPU**: 8+ cores
- **RAM**: 16 GB+
- **Disk**: 50 GB+ SSD
- **Network**: Broadband (for initial model download)

### Software
- Node.js 20.x or 22.x (not 24.x)
- Docker 20.10+
- Docker Compose v2.0+

## Quick Start

### 1. Start Infrastructure

```bash
cd ~/claude-context-deployment
./scripts/start.sh
```

This will:
- Start Milvus (vector database)
- Start etcd (metadata storage)
- Start MinIO (object storage)
- Start Ollama (embedding service)

### 2. Setup Ollama Embedding Model

```bash
./scripts/setup-ollama.sh
```

Default model: `nomic-embed-text` (274 MB, 768 dimensions)

Alternative models:
```bash
./scripts/setup-ollama.sh mxbai-embed-large  # 669 MB, 1024 dimensions
./scripts/setup-ollama.sh all-minilm         # 46 MB, 384 dimensions
```

### 3. Configure Claude Code

Edit `~/.config/claude-code/config.json`:

```json
{
  "mcpServers": {
    "claude-context": {
      "command": "npx",
      "args": ["-y", "@zilliz/claude-context-mcp@latest"],
      "env": {
        "MILVUS_ADDRESS": "http://localhost:19530",
        "MILVUS_TOKEN": "",
        "OLLAMA_BASE_URL": "http://localhost:11434",
        "EMBEDDING_PROVIDER": "ollama",
        "EMBEDDING_MODEL": "nomic-embed-text"
      }
    }
  }
}
```

### 4. Restart Claude Code

Restart Claude Code to load the MCP server.

### 5. Verify Deployment

```bash
./scripts/test-deployment.sh
```

## Usage

### Index a Codebase

In Claude Code:
```
Please index this codebase
```

### Search Code

```
Find all authentication-related functions
```

```
Show me error handling patterns
```

## Management Scripts

All scripts are in `./scripts/`:

| Script | Description |
|--------|-------------|
| `start.sh` | Start all services |
| `stop.sh` | Stop all services |
| `logs.sh [service]` | View logs |
| `setup-ollama.sh [model]` | Download embedding model |
| `test-deployment.sh` | Run health checks |
| `clean.sh` | Remove all data and reset |

### Examples

```bash
# View all logs
./scripts/logs.sh

# View specific service logs
./scripts/logs.sh milvus
./scripts/logs.sh ollama

# Stop everything
./scripts/stop.sh

# Clean and reset (WARNING: deletes all data)
./scripts/clean.sh
```

## Service Endpoints

| Service | Endpoint | Description |
|---------|----------|-------------|
| Milvus gRPC | `localhost:19530` | Vector database API |
| Milvus Health | `localhost:9091/healthz` | Health check |
| MinIO API | `localhost:9000` | Object storage |
| MinIO Console | `localhost:9001` | Web UI (admin/minioadmin) |
| Ollama API | `localhost:11434` | Embedding generation |

## Data Persistence

All data is stored in `./data/`:

```
data/
├── milvus/     # Vector collections and indexes
├── etcd/       # Metadata and schemas
├── minio/      # Object files (vectors, logs)
└── ollama/     # Downloaded models
```

**Backup Strategy:**

```bash
# Backup all data
tar -czf backup-$(date +%Y%m%d).tar.gz data/

# Restore from backup
tar -xzf backup-20241027.tar.gz
```

## Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
docker ps

# Check logs for errors
./scripts/logs.sh milvus

# Clean and restart
./scripts/stop.sh
./scripts/clean.sh  # Warning: deletes data
./scripts/start.sh
```

### Milvus Health Check Fails

```bash
# Check Milvus logs
docker logs milvus-standalone

# Verify dependencies
curl http://localhost:9000/minio/health/live  # MinIO
docker exec milvus-etcd etcdctl endpoint health  # etcd

# Restart Milvus
docker restart milvus-standalone
```

### Ollama Model Not Found

```bash
# List available models
docker exec ollama ollama list

# Pull model manually
docker exec ollama ollama pull nomic-embed-text

# Test embedding generation
curl http://localhost:11434/api/embeddings -d '{
  "model": "nomic-embed-text",
  "prompt": "test"
}'
```

### Claude Code Can't Connect to MCP

1. Check MCP server in Claude Code settings
2. Verify environment variables in config.json
3. Test Milvus connectivity:
   ```bash
   curl http://localhost:19530  # Should not refuse connection
   curl http://localhost:9091/healthz  # Should return OK
   ```
4. Check Claude Code logs for MCP errors
5. Restart Claude Code

### High Memory Usage

Edit `docker-compose.milvus.yml` and adjust:

```yaml
environment:
  MILVUS_QUERY_NODE_CACHE_MEMORY_LIMIT: 2147483648  # 2GB (was 4GB)
  MILVUS_INDEX_NODE_CACHE_MEMORY_LIMIT: 1073741824  # 1GB (was 2GB)
```

Then restart:
```bash
./scripts/stop.sh && ./scripts/start.sh
```

### Port Conflicts

If ports are already in use, edit docker-compose files:

**Milvus (docker-compose.milvus.yml):**
```yaml
ports:
  - "19530:19530"  # Change to "19531:19530" if conflict
```

**Ollama (docker-compose.ollama.yml):**
```yaml
ports:
  - "11434:11434"  # Change to "11435:11434" if conflict
```

Then update MCP config accordingly.

## Performance Tuning

### Embedding Model Selection

| Model | Size | Dimensions | Speed | Quality |
|-------|------|------------|-------|---------|
| all-minilm | 46 MB | 384 | Fast | Good |
| nomic-embed-text | 274 MB | 768 | Medium | Excellent |
| mxbai-embed-large | 669 MB | 1024 | Slower | Best |

### Milvus Index Optimization

For large codebases (>100k files), consider tuning Milvus index parameters.

See: https://milvus.io/docs/index.md

## Upgrading

### Update MCP Server

The MCP server auto-updates when using `npx -y`. To pin a version:

```json
"args": ["-y", "@zilliz/claude-context-mcp@1.2.3"]
```

### Update Milvus

```bash
# Edit docker-compose.milvus.yml
# Change: image: milvusdb/milvus:v2.3.3
# To:     image: milvusdb/milvus:v2.4.0

./scripts/stop.sh
docker compose -f docker-compose.milvus.yml pull
./scripts/start.sh
```

### Update Ollama

```bash
docker compose -f docker-compose.ollama.yml pull
docker compose -f docker-compose.ollama.yml up -d
```

## Resource Usage Estimates

### Idle State
- Milvus: ~500 MB RAM
- etcd: ~50 MB RAM
- MinIO: ~100 MB RAM
- Ollama: ~200 MB RAM
- **Total**: ~850 MB RAM

### Active Indexing (10k files)
- Milvus: ~2-4 GB RAM
- Ollama: ~500 MB - 1 GB RAM
- **Total**: ~3-5 GB RAM

### Disk Usage
- Milvus data: ~10-50 MB per 1000 files indexed
- Ollama models: 46 MB - 669 MB per model
- Logs: ~10 MB per day

## Security Considerations

### Production Deployment

If exposing services beyond localhost:

1. **Change MinIO credentials**:
   ```bash
   # Edit .env
   MINIO_ROOT_USER=your-secure-user
   MINIO_ROOT_PASSWORD=your-secure-password
   ```

2. **Enable Milvus authentication**:
   See: https://milvus.io/docs/authenticate.md

3. **Use reverse proxy** (nginx/Traefik) with TLS

4. **Firewall rules**:
   - Only expose necessary ports
   - Use Docker network isolation

## Monitoring

### Check Service Health

```bash
# Quick health check
curl http://localhost:9091/healthz  # Milvus
curl http://localhost:11434/api/version  # Ollama

# Container stats
docker stats milvus-standalone ollama

# Disk usage
du -sh data/*
```

### Prometheus Metrics

Milvus exposes Prometheus metrics on port 9091:

```bash
curl http://localhost:9091/metrics
```

## Uninstall

```bash
# Stop and remove containers
./scripts/stop.sh

# Remove all data
./scripts/clean.sh

# Remove deployment directory
cd ~
rm -rf claude-context-deployment

# Remove Claude Code MCP config
# Edit ~/.config/claude-code/config.json and remove "claude-context" entry
```

## Additional Resources

- [Claude Context MCP GitHub](https://github.com/zilliztech/claude-context-mcp)
- [Milvus Documentation](https://milvus.io/docs)
- [Ollama Documentation](https://ollama.ai/docs)
- [Claude Code MCP Guide](https://docs.anthropic.com/claude/docs/model-context-protocol)

## Support

For issues:
1. Run `./scripts/test-deployment.sh` and share output
2. Check logs: `./scripts/logs.sh [service]`
3. Open issue on GitHub with system info and logs

## License

This deployment configuration is provided as-is. Component licenses:
- Milvus: Apache 2.0
- Ollama: MIT
- Claude Context MCP: Check package repository
