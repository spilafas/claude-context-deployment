# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Claude Code (MCP Client)                 │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  User asks: "Find all authentication functions"          │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────┘
                      │ MCP Protocol
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│              Claude Context MCP Server                          │
│              (npx @zilliz/claude-context-mcp)                   │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   Indexer    │  │   Searcher   │  │   Manager    │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└──────────┬────────────────────┬─────────────────────────────────┘
           │                    │
           │ Store vectors      │ Generate embeddings
           ▼                    ▼
┌──────────────────────┐  ┌──────────────────────┐
│   Milvus Stack       │  │   Ollama Service     │
│                      │  │                      │
│  ┌────────────────┐ │  │  ┌────────────────┐ │
│  │    Milvus      │ │  │  │ Embedding      │ │
│  │  (Vector DB)   │ │  │  │ Model          │ │
│  │                │ │  │  │                │ │
│  │  Port: 19530   │ │  │  │ nomic-embed    │ │
│  └────────────────┘ │  │  │ -text          │ │
│                      │  │  │                │ │
│  ┌────────────────┐ │  │  │ Port: 11434    │ │
│  │     etcd       │ │  │  └────────────────┘ │
│  │  (Metadata)    │ │  │                      │
│  └────────────────┘ │  └──────────────────────┘
│                      │
│  ┌────────────────┐ │
│  │     MinIO      │ │
│  │   (Storage)    │ │
│  │                │ │
│  │  Port: 9000    │ │
│  │  UI:   9001    │ │
│  └────────────────┘ │
└──────────────────────┘
```

## Data Flow

### 1. Indexing Flow

```
Code Files ──┐
             │
             ├─> Read files
             │
             ├─> Chunk code into segments
             │
             ├─> Send to Ollama for embedding
             │         │
             │         ▼
             │   ┌──────────────┐
             │   │ Ollama Model │
             │   │ (768-dim)    │
             │   └──────────────┘
             │         │
             │         ▼
             │   Vector embeddings
             │         │
             │         ▼
             └─> Store in Milvus
                       │
                       ▼
                 ┌──────────────┐
                 │ Collections  │
                 │ - code_chunks│
                 │ - metadata   │
                 └──────────────┘
```

### 2. Search Flow

```
User Query ──> Claude Context MCP
                       │
                       ├─> Generate query embedding (Ollama)
                       │         │
                       │         ▼
                       │   Query Vector (768-dim)
                       │         │
                       ├─────────┘
                       │
                       ├─> Vector similarity search (Milvus)
                       │         │
                       │         ▼
                       │   Top-K similar vectors
                       │         │
                       │         ▼
                       │   Retrieve metadata & code
                       │         │
                       └─────────┘
                       │
                       ▼
                 Results to Claude Code
```

## Component Details

### Claude Context MCP Server

**Role**: Bridge between Claude Code and vector database

**Responsibilities**:
- Parse codebase files
- Chunk code into searchable segments
- Manage indexing pipeline
- Handle search queries
- Return relevant code snippets

**Technology**: Node.js (NPX package)

### Milvus Vector Database

**Role**: Store and search vector embeddings

**Components**:

1. **Milvus Standalone**
   - Vector storage engine
   - Similarity search (ANN)
   - Collection management
   - Index building (HNSW, IVF, etc.)

2. **etcd**
   - Service discovery
   - Metadata storage
   - Collection schemas
   - Configuration

3. **MinIO**
   - Object storage
   - Vector data files
   - Index files
   - Snapshots & backups

**Technology**: Go, C++

### Ollama

**Role**: Generate vector embeddings from text

**Model**: nomic-embed-text (default)
- **Input**: Text string (code segment)
- **Output**: 768-dimensional vector
- **Performance**: ~100-500 embeddings/sec (depends on hardware)

**Technology**: Go, GGML

## Network Topology

```
┌─────────────────────────────────────────────────────────┐
│                    localhost                            │
│                                                         │
│  ┌─────────────┐                                       │
│  │ Claude Code │                                       │
│  └──────┬──────┘                                       │
│         │ Spawns process                               │
│         ▼                                               │
│  ┌────────────────────┐                                │
│  │ MCP Server Process │                                │
│  │ (Node.js)          │                                │
│  └─────┬──────────┬───┘                                │
│        │          │                                     │
│        │ :19530   │ :11434                             │
│        │          │                                     │
│  ┌─────▼──────┐  ┌▼──────────┐                        │
│  │  Milvus    │  │  Ollama   │                        │
│  │  Network   │  │  Network  │                        │
│  │            │  │           │                        │
│  │  - etcd    │  │           │                        │
│  │  - minio   │  └───────────┘                        │
│  │  - milvus  │                                        │
│  └────────────┘                                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Storage Architecture

```
~/claude-context-deployment/data/
│
├── milvus/
│   ├── index/           # Vector indexes (HNSW, IVF)
│   ├── wal/            # Write-ahead logs
│   └── meta/           # Local metadata cache
│
├── etcd/
│   ├── member/
│   │   ├── snap/       # Snapshots
│   │   └── wal/        # Transaction logs
│   └── data/           # Key-value store
│
├── minio/
│   └── milvus/
│       ├── collections/ # Collection data
│       ├── segments/    # Vector segments
│       └── logs/        # Binlogs
│
└── ollama/
    └── models/
        └── blobs/       # Model weights (GGUF files)
```

## Scalability Considerations

### Current Setup (Standalone)

- **Max Collections**: 256
- **Max Vectors/Collection**: ~100M (depends on RAM)
- **Concurrent Queries**: 10-50
- **Throughput**: 1K-10K QPS

### Performance Optimization

1. **Index Type Selection**:
   - HNSW: Best accuracy, high memory
   - IVF_FLAT: Good balance
   - IVF_PQ: Low memory, lower accuracy

2. **Resource Tuning**:
   ```yaml
   QUERY_MEMORY_LIMIT: 4GB  # Query cache
   INDEX_MEMORY_LIMIT: 2GB  # Index building
   ```

3. **Embedding Model**:
   - Smaller models: Faster, less accurate
   - Larger models: Slower, more accurate

### Scaling Up

For large deployments (>1M files):

1. **Increase Docker resources**:
   - Docker Desktop → Settings → Resources
   - RAM: 8-16 GB
   - CPU: 4-8 cores

2. **Use larger instance types** (cloud deployment)

3. **Consider Milvus Cluster** mode:
   - Distributed architecture
   - Horizontal scaling
   - High availability

## Security Model

### Current (Local Development)

- No authentication on Milvus
- No authentication on Ollama
- All services on localhost
- Docker network isolation

### Production Hardening

1. **Enable Milvus Auth**:
   ```yaml
   environment:
     MILVUS_AUTHORIZATION_ENABLED: true
   ```

2. **Secure MinIO**:
   ```yaml
   MINIO_ROOT_USER: secure-username
   MINIO_ROOT_PASSWORD: secure-password-32-chars
   ```

3. **Network Policies**:
   - Firewall rules
   - VPN access only
   - Reverse proxy with TLS

4. **Encryption**:
   - TLS for all connections
   - Encryption at rest (MinIO, etcd)

## Monitoring & Observability

### Health Endpoints

| Service | Endpoint | Check |
|---------|----------|-------|
| Milvus | `http://localhost:9091/healthz` | Returns "OK" |
| Ollama | `http://localhost:11434/api/version` | Returns version JSON |
| MinIO | `http://localhost:9000/minio/health/live` | Returns 200 |

### Metrics

**Milvus Prometheus Metrics**:
```bash
curl http://localhost:9091/metrics
```

Key metrics:
- `milvus_querynode_search_latency`
- `milvus_datanode_insert_throughput`
- `milvus_indexnode_build_duration`

### Logging

All services log to Docker:
```bash
docker logs milvus-standalone
docker logs ollama
docker logs milvus-minio
docker logs milvus-etcd
```

## Backup & Recovery

### Backup Strategy

```bash
# Stop services
./scripts/stop.sh

# Backup data
tar -czf backup-$(date +%Y%m%d).tar.gz data/

# Restart services
./scripts/start.sh
```

### Recovery

```bash
# Stop services
./scripts/stop.sh

# Restore data
tar -xzf backup-20241027.tar.gz

# Restart services
./scripts/start.sh
```

### Automated Backups

Create cron job:
```bash
# Daily backup at 2 AM
0 2 * * * cd ~/claude-context-deployment && tar -czf ~/backups/claude-context-$(date +\%Y\%m\%d).tar.gz data/
```

## Disaster Recovery

### Complete Reset

```bash
./scripts/clean.sh    # Deletes all data
./scripts/start.sh    # Fresh start
./scripts/setup-ollama.sh  # Re-download model
```

### Partial Recovery

**Milvus only**:
```bash
docker compose -f docker-compose.milvus.yml down
rm -rf data/milvus/*
docker compose -f docker-compose.milvus.yml up -d
```

**Ollama only**:
```bash
docker compose -f docker-compose.ollama.yml down
rm -rf data/ollama/*
docker compose -f docker-compose.ollama.yml up -d
./scripts/setup-ollama.sh
```

## Cost Analysis

### Self-Hosted (This Deployment)

**One-time**:
- Setup time: 30 minutes
- No monetary cost

**Recurring**:
- Electricity: ~$2-5/month (idle)
- No cloud fees
- No API costs

### Cloud Alternative (Zilliz Cloud + OpenAI)

**Recurring**:
- Zilliz Cloud: $20-100/month
- OpenAI API: $0.0001/1K tokens (~$5-50/month)
- Total: $25-150/month

**Savings**: ~$300-1800/year with self-hosted! 💰

---

**Last Updated**: 2025-10-27
**Version**: 1.0
