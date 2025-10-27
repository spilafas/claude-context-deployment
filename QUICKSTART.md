# Quick Start Guide

Get Claude Context MCP running in 5 minutes!

## Prerequisites

✅ Docker and Docker Compose installed
✅ Node.js v20 or v22 installed
✅ Claude Code installed

## Step 1: Start Services (2 minutes)

```bash
cd ~/claude-context-deployment
./scripts/start.sh
```

Wait for all services to start (60-90 seconds).

## Step 2: Download Embedding Model (1-2 minutes)

```bash
./scripts/setup-ollama.sh
```

This downloads the `nomic-embed-text` model (~274 MB).

## Step 3: Verify Everything Works (30 seconds)

```bash
./scripts/test-deployment.sh
```

You should see all tests pass ✅

## Step 4: Configure Claude Code (1 minute)

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

## Step 5: Restart Claude Code

Quit and restart Claude Code.

## Step 6: Test in Claude Code

Open a codebase in Claude Code and say:

```
Please index this codebase
```

Then try searching:

```
Find all authentication functions
```

## Done!

You now have a fully self-hosted Claude Context deployment!

## Daily Usage

**Start services:**
```bash
cd ~/claude-context-deployment
./scripts/start.sh
```

**Stop services:**
```bash
./scripts/stop.sh
```

**Check status:**
```bash
./scripts/test-deployment.sh
```

## Troubleshooting

If something doesn't work:

1. Check logs: `./scripts/logs.sh`
2. Restart: `./scripts/stop.sh && ./scripts/start.sh`
3. See [README.md](README.md) for detailed troubleshooting

## Resource Usage

- **RAM**: ~1-3 GB when idle, 3-5 GB when indexing
- **Disk**: ~1-5 GB for infrastructure + indexed data
- **CPU**: Minimal when idle, 1-2 cores when indexing

## Alternative Models

Want a different embedding model?

**Smaller/Faster** (all-minilm, 46 MB):
```bash
./scripts/setup-ollama.sh all-minilm
```
Then update `EMBEDDING_MODEL` in Claude Code config to `all-minilm`.

**Larger/Better** (mxbai-embed-large, 669 MB):
```bash
./scripts/setup-ollama.sh mxbai-embed-large
```
Then update `EMBEDDING_MODEL` in Claude Code config to `mxbai-embed-large`.

## Next Steps

- Read [README.md](README.md) for comprehensive documentation
- See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for advanced config options
- Check out management scripts in `scripts/`

Enjoy your self-hosted Claude Context! 🚀
