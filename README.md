# MCP Manager

A system for dynamically managing Model Context Protocol (MCP) servers in Claude Code. Provides both global defaults and per-project configurations, allowing quick switching between different MCP setups based on project needs.

## Problem Solved

Managing MCPs in Claude Code requires manual command-line operations (`claude mcp add/remove`). Users working on multiple projects with different MCP needs must manually reconfigure their setup when switching contexts. MCP Manager solves this by providing:

- Per-project MCP configurations (`.mcp-project.json`)
- Global registry of all known MCPs with rich metadata
- Interactive `/mcp-manage` slash command for Claude Code
- Shell helpers for terminal-based management
- Profile support for common workflow presets

## Quick Start

### Prerequisites

- [Claude Code CLI](https://claude.ai/claude-code) installed
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running (for Docker MCP servers)
- macOS or Linux (Windows WSL supported)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/mcpManager.git
   cd mcpManager
   ```

2. **Run the setup script:**
   ```bash
   ./scripts/setup.sh
   ```

   This will:
   - Create `~/.config/claude-mcp/` directory
   - Install the global registry (`registry.json`)
   - Install shell helpers (`mcp-helpers.sh`)
   - Install the `/mcp-manage` slash command

3. **Source the shell helpers** (add to your `~/.zshrc` or `~/.bashrc`):
   ```bash
   source ~/.config/claude-mcp/mcp-helpers.sh
   ```

4. **Verify installation:**
   ```bash
   mcp-status
   ```

## Usage

### In Claude Code

#### Session Start (Automatic)
When you start a Claude Code session in a project with `.mcp-project.json`, the system automatically checks if your MCP configuration matches the project requirements.

#### Interactive Management
Run the `/mcp-manage` slash command for interactive MCP management:

```
/mcp-manage
```

This provides:
- **Status View** - See enabled MCPs and context token usage
- **Enable/Disable** - Toggle specific MCPs on/off
- **Discovery** - Browse and add MCPs from Docker catalog
- **Save/Load** - Manage project configurations

### From Terminal

```bash
# Show current MCP status
mcp-status

# Apply project config from current directory
mcp-apply

# List enabled MCPs (native Claude CLI)
claude mcp list
```

## Project Configuration

Create a `.mcp-project.json` in your project root:

```json
{
  "project": "my-project",
  "description": "Description of what this project does",
  "enabled": ["MCP_DOCKER"],
  "disabled": ["aws-api"],
  "notes": "Optional notes about this configuration"
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `project` | Yes | Project name identifier |
| `description` | No | Human-readable project description |
| `enabled` | Yes | Array of MCP names to enable |
| `disabled` | No | Array of MCP names to explicitly disable |
| `profile` | No | Named profile to apply (from global registry) |
| `notes` | No | Additional notes about the configuration |

## Global Registry

The global registry (`~/.config/claude-mcp/registry.json`) is the single source of truth for all MCPs:

```json
{
  "version": "1.0",
  "servers": {
    "MCP_DOCKER": {
      "status": "active",
      "source": "docker-gateway",
      "description": "Docker MCP Gateway - browser automation, docs lookup, AWS tools",
      "capabilities": [
        "Browser automation via Playwright",
        "Documentation lookup via Context7",
        "AWS CLI execution"
      ],
      "command": ["docker", "mcp", "gateway", "run"],
      "context_tokens": 20000,
      "tags": ["browser", "docs", "aws", "gateway"]
    }
  },
  "profiles": {
    "minimal": {
      "description": "Just Context7 for docs lookup",
      "mcps": ["MCP_DOCKER"]
    }
  }
}
```

### Server Fields

| Field | Required | Description |
|-------|----------|-------------|
| `status` | Yes | "active" or "archived" |
| `source` | Yes | "docker", "docker-gateway", "npx", "local" |
| `description` | Yes | Human-readable description |
| `capabilities` | Yes | Array of specific capabilities |
| `command` | Yes | Command array to launch the MCP |
| `context_tokens` | Yes | Estimated context window usage |
| `tags` | Yes | Keywords for searching/filtering |

## Architecture

```
~/.config/claude-mcp/
├── registry.json       # Global MCP registry (single source of truth)
└── mcp-helpers.sh      # Shell functions for terminal management

~/.claude/commands/
└── mcp-manage.md       # /mcp-manage slash command definition

<project>/
├── .mcp-project.json   # Project-specific MCP configuration
└── CLAUDE.md           # Session instructions (includes MCP check)
```

## Available MCPs

### Default MCPs

| Name | Description | Context Tokens |
|------|-------------|----------------|
| `MCP_DOCKER` | Docker Gateway - Playwright, Context7, AWS tools | ~20,000 |
| `aws-api` | Standalone AWS CLI execution | ~2,000 |

### Discovering More MCPs

The Docker MCP catalog contains 300+ servers. Discover them via:

```bash
# From terminal
docker mcp catalog show

# In Claude Code (with MCP_DOCKER enabled)
# Use the mcp-find tool or /mcp-manage discovery
```

Categories include:
- **Databases** - PostgreSQL, MySQL, MongoDB, Redis
- **Cloud** - AWS, GCP, Azure tools
- **Documentation** - Context7, ReadTheDocs
- **Browser** - Playwright, Puppeteer
- **AI/ML** - Various AI service integrations

## Shell Helpers Reference

After sourcing `mcp-helpers.sh`:

| Command | Description |
|---------|-------------|
| `mcp-status` | Show currently enabled MCPs |
| `mcp-apply` | Apply `.mcp-project.json` from current directory |

## Troubleshooting

### MCP fails to start
1. Ensure Docker Desktop is running
2. Check the MCP command is correct in registry
3. Try running the command manually to see errors

### Docker not running
```bash
open -a Docker
# Wait for Docker to start, then retry
```

### Permission issues
```bash
chmod +x ~/.config/claude-mcp/mcp-helpers.sh
```

### Registry file corrupted
```bash
# Backup and recreate
cp ~/.config/claude-mcp/registry.json ~/.config/claude-mcp/registry.json.bak
./scripts/setup.sh
```

## Development

### Project Structure

```
mcpManager/
├── README.md                 # This file
├── CLAUDE.md                 # Claude Code session instructions
├── .mcp-project.json         # MCP config for this project
├── docs/
│   └── PRD.md               # Product Requirements Document
├── scripts/
│   ├── setup.sh             # Installation script
│   ├── build.sh             # Build script
│   └── test.sh              # Test runner
└── .claude/
    └── settings.local.json  # Local Claude permissions
```

### Running Tests

```bash
./scripts/test.sh
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

MIT License - See LICENSE file for details.

## Related Links

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Docker MCP Catalog](https://hub.docker.com/u/mcp)
