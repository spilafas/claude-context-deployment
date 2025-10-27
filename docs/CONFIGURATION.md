# Claude Code MCP Configuration Guide

## Step-by-Step Configuration

### 1. Locate Claude Code Config File

The configuration file is located at:

**macOS/Linux:**
```
~/.config/claude-code/config.json
```

**Windows:**
```
%APPDATA%\claude-code\config.json
```

### 2. Backup Existing Config (Optional)

```bash
cp ~/.config/claude-code/config.json ~/.config/claude-code/config.json.backup
```

### 3. Edit Configuration

Open the file in your editor:

```bash
# macOS
open -e ~/.config/claude-code/config.json

# Linux
nano ~/.config/claude-code/config.json
```

### 4. Add MCP Server Entry

If the file doesn't exist or is empty, create it with:

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

If you already have other MCP servers configured, add the `claude-context` entry to the existing `mcpServers` object:

```json
{
  "mcpServers": {
    "existing-server": {
      "command": "...",
      "args": ["..."]
    },
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

### 5. Verify JSON Syntax

Ensure your JSON is valid:

```bash
# macOS/Linux with jq
cat ~/.config/claude-code/config.json | jq .

# Or use an online JSON validator
```

### 6. Restart Claude Code

Completely quit and restart Claude Code for changes to take effect.

## Configuration Options

### Milvus Settings

```json
"MILVUS_ADDRESS": "http://localhost:19530"
```
- Default: `http://localhost:19530`
- Change if using custom port or remote Milvus

```json
"MILVUS_TOKEN": ""
```
- Leave empty for local unauthenticated Milvus
- Set to auth token if Milvus authentication is enabled

### Ollama Settings

```json
"OLLAMA_BASE_URL": "http://localhost:11434"
```
- Default: `http://localhost:11434`
- Change if Ollama is on different port or remote host

```json
"EMBEDDING_PROVIDER": "ollama"
```
- Must be `ollama` for self-hosted setup

```json
"EMBEDDING_MODEL": "nomic-embed-text"
```
- Default: `nomic-embed-text` (768 dimensions)
- Alternative: `mxbai-embed-large` (1024 dimensions)
- Alternative: `all-minilm` (384 dimensions)
- Must match a model you've pulled in Ollama

### Optional: Debug Logging

Add to `env` section:

```json
"env": {
  "MILVUS_ADDRESS": "http://localhost:19530",
  "DEBUG": "true"
}
```

## Verifying Configuration

### 1. Check MCP Server Status

In Claude Code, you should see the MCP server listed in the status bar or settings.

### 2. Test MCP Connection

Try asking Claude Code:

```
What MCP servers are available?
```

You should see `claude-context` in the list.

### 3. Test Indexing

```
Please index this codebase
```

Claude Code should start indexing files into Milvus.

### 4. Test Search

After indexing completes:

```
Find all functions related to authentication
```

## Troubleshooting

### MCP Server Not Appearing

**Check 1: Config file location**
```bash
ls -la ~/.config/claude-code/config.json
```

**Check 2: JSON syntax**
```bash
cat ~/.config/claude-code/config.json | jq .
```

**Check 3: Claude Code logs**
- Look for MCP-related errors in Claude Code console

### MCP Server Failing to Start

**Check 1: Node.js version**
```bash
node --version  # Should be v20.x or v22.x
```

**Check 2: NPX access**
```bash
npx -y @zilliz/claude-context-mcp@latest --help
```

**Check 3: Network connectivity**
```bash
curl http://localhost:19530  # Milvus
curl http://localhost:11434/api/version  # Ollama
```

### Indexing Fails

**Check 1: Milvus is running**
```bash
curl http://localhost:9091/healthz
```

**Check 2: Ollama model is available**
```bash
docker exec ollama ollama list
```

**Check 3: Model name matches config**
- Ensure `EMBEDDING_MODEL` in config.json matches model in Ollama

### Search Returns No Results

**Check 1: Indexing completed**
- Verify indexing finished without errors

**Check 2: Collection exists in Milvus**
```bash
# This requires pymilvus or Milvus SDK
# See Milvus documentation for querying collections
```

**Check 3: Try re-indexing**
```
Please re-index this codebase
```

## Advanced Configuration

### Using Remote Milvus

If Milvus is on a different machine:

```json
"env": {
  "MILVUS_ADDRESS": "http://192.168.1.100:19530",
  "MILVUS_TOKEN": "your-auth-token-if-enabled"
}
```

### Using Remote Ollama

If Ollama is on a different machine:

```json
"env": {
  "OLLAMA_BASE_URL": "http://192.168.1.101:11434"
}
```

### Custom Collection Name

```json
"env": {
  "MILVUS_COLLECTION_NAME": "my_custom_collection"
}
```

### Performance Tuning

```json
"env": {
  "BATCH_SIZE": "100",
  "MAX_CONCURRENT_REQUESTS": "10"
}
```

Note: These variables depend on the MCP server implementation. Check the package documentation for available options.

## Example Configurations

### Minimal (All Defaults)

```json
{
  "mcpServers": {
    "claude-context": {
      "command": "npx",
      "args": ["-y", "@zilliz/claude-context-mcp@latest"],
      "env": {
        "MILVUS_ADDRESS": "http://localhost:19530",
        "OLLAMA_BASE_URL": "http://localhost:11434",
        "EMBEDDING_PROVIDER": "ollama",
        "EMBEDDING_MODEL": "nomic-embed-text"
      }
    }
  }
}
```

### With Large Embedding Model

```json
{
  "mcpServers": {
    "claude-context": {
      "command": "npx",
      "args": ["-y", "@zilliz/claude-context-mcp@latest"],
      "env": {
        "MILVUS_ADDRESS": "http://localhost:19530",
        "OLLAMA_BASE_URL": "http://localhost:11434",
        "EMBEDDING_PROVIDER": "ollama",
        "EMBEDDING_MODEL": "mxbai-embed-large"
      }
    }
  }
}
```

### With Debug Logging

```json
{
  "mcpServers": {
    "claude-context": {
      "command": "npx",
      "args": ["-y", "@zilliz/claude-context-mcp@latest"],
      "env": {
        "MILVUS_ADDRESS": "http://localhost:19530",
        "OLLAMA_BASE_URL": "http://localhost:11434",
        "EMBEDDING_PROVIDER": "ollama",
        "EMBEDDING_MODEL": "nomic-embed-text",
        "DEBUG": "true"
      }
    }
  }
}
```

## Next Steps

After configuration:

1. **Restart Claude Code**
2. **Verify MCP server is loaded**
3. **Index a test codebase**: `index this codebase`
4. **Test semantic search**: `find authentication functions`
5. **Monitor logs** if issues occur

For more help, see the main [README.md](../README.md).
