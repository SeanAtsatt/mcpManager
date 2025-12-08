# MCP Manager

A system for dynamically managing Model Context Protocol (MCP) servers in Claude Code. Provides both global defaults and per-project configurations, allowing quick switching between different MCP setups based on project needs.

## Problem Solved

Managing MCPs in Claude Code requires manual command-line operations (`claude mcp add/remove`). Users working on multiple projects with different MCP needs must manually reconfigure their setup when switching contexts. MCP Manager solves this by providing:

- Per-project MCP configurations (`.mcp-project.json`)
- Global registry of all known MCPs with rich metadata
- Interactive `/mcp-manage` slash command for Claude Code
- Shell helpers for terminal-based management
- Profile support for common workflow presets
- Archive management for soft-deleting unused MCPs

## Quick Start

### Prerequisites

- [Claude Code CLI](https://claude.ai/claude-code) installed
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running (for Docker MCP servers)
- Python 3.x (for helper scripts)
- macOS or Linux (Windows WSL supported)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/SeanAtsatt/mcpManager.git
   cd mcpManager
   ```

2. **Run build validation:**
   ```bash
   ./scripts/build.sh
   ```

3. **Run the setup script:**
   ```bash
   ./scripts/setup.sh
   ```

   This will:
   - Create `~/.config/claude-mcp/` directory
   - Install the global registry (`registry.json`)
   - Install shell helpers (`mcp-helpers.sh`)
   - Install the `/mcp-manage` slash command

4. **Source the shell helpers** (add to your `~/.zshrc` or `~/.bashrc`):
   ```bash
   source ~/.config/claude-mcp/mcp-helpers.sh
   ```

5. **Verify installation:**
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
- **Profiles** - Apply or create workflow presets
- **Archives** - View and restore archived MCPs
- **Save/Load** - Manage project configurations

### From Terminal

#### Interactive CLI
```bash
./scripts/run.sh
```

Launches an interactive menu for all MCP management operations.

#### Shell Commands
```bash
# Status and info
mcp-status      # Show enabled MCPs with token usage
mcp-list        # List all available MCPs in registry
mcp-profiles    # List available profiles

# Apply configurations
mcp-apply       # Apply .mcp-project.json from current directory
mcp-profile <name>  # Apply a named profile

# Search and discover
mcp-search <term>   # Search MCPs by keyword

# Save configurations
mcp-save [name]     # Save current MCPs to .mcp-project.json
mcp-profile-create <name> [description]  # Create profile from current MCPs

# Archive management
mcp-archive <name> [reason]  # Archive an MCP
mcp-restore <name>           # Restore from archive
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
  "last_updated": "2024-12-07T19:00:00Z",
  "profiles": {
    "minimal": {
      "description": "Just the Docker Gateway for docs lookup",
      "mcps": ["MCP_DOCKER"],
      "created": "2024-12-07",
      "last_used": null
    },
    "aws-dev": {
      "description": "AWS development with full tooling",
      "mcps": ["MCP_DOCKER", "aws-api"],
      "created": "2024-12-07",
      "last_used": null
    }
  },
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
      "tags": ["browser", "docs", "aws", "gateway"],
      "added": "2024-12-07",
      "last_used": "2024-12-07",
      "use_count": 42,
      "notes": "Primary gateway - includes most common tools"
    }
  },
  "archived": {},
  "config": {
    "default_profile": null,
    "auto_apply_on_cd": false,
    "sync_with_docker_catalog": true
  }
}
```

### Server Fields

| Field | Required | Description |
|-------|----------|-------------|
| `status` | Yes | "active" or "archived" |
| `source` | Yes | "docker", "docker-gateway", "npx", "local", "remote" |
| `description` | Yes | Human-readable description |
| `capabilities` | Yes | Array of specific capabilities |
| `command` | Yes | Command array to launch the MCP |
| `context_tokens` | Yes | Estimated context window usage |
| `tags` | Yes | Keywords for searching/filtering |
| `added` | Yes | Date MCP was added |
| `last_used` | No | Date MCP was last enabled |
| `use_count` | No | Number of times enabled |
| `notes` | No | User notes about the MCP |

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

### Default Profiles

| Profile | Description | MCPs |
|---------|-------------|------|
| `minimal` | Just docs lookup | MCP_DOCKER |
| `aws-dev` | AWS development | MCP_DOCKER, aws-api |
| `web-frontend` | Web development | MCP_DOCKER |
| `data-engineering` | Data pipelines | MCP_DOCKER, aws-api |

### Discovering More MCPs

The Docker MCP catalog contains 300+ servers. Discover them via:

```bash
# From terminal
docker mcp catalog show

# Search for specific capabilities
mcp-search database
mcp-search aws

# In Claude Code (with MCP_DOCKER enabled)
# Use the mcp-find tool or /mcp-manage discovery
```

Categories include:
- **Databases** - PostgreSQL, MySQL, MongoDB, Redis
- **Cloud** - AWS, GCP, Azure tools
- **Documentation** - Context7, ReadTheDocs
- **Browser** - Playwright, Puppeteer
- **AI/ML** - Various AI service integrations

## Development

### Project Structure

```
mcpManager/
├── README.md                 # This file
├── CLAUDE.md                 # Claude Code session instructions
├── .mcp-project.json         # MCP config for this project
├── docs/
│   ├── PRD.md               # Product Requirements Document
│   └── testing_strategy.md  # Testing documentation
├── src/
│   ├── registry.json        # Registry template
│   ├── mcp-helpers.sh       # Shell helpers source
│   └── mcp-manage.md        # Slash command source
├── scripts/
│   ├── setup.sh             # Installation script
│   ├── build.sh             # Build/validation script
│   ├── test.sh              # Test runner
│   └── run.sh               # Interactive CLI
└── tests/                   # Test files (created at runtime)
```

### Scripts

| Script | Description |
|--------|-------------|
| `./scripts/build.sh` | Validate source files, JSON, and shell syntax |
| `./scripts/test.sh` | Run full test suite |
| `./scripts/setup.sh` | Install to system |
| `./scripts/run.sh` | Interactive CLI |

### Running Tests

```bash
# Run all tests
./scripts/test.sh

# Run build validation only
./scripts/build.sh
```

### Test Coverage

The test suite includes:
- **Unit tests** - JSON validation, schema compliance, syntax checks
- **Integration tests** - Registry operations, archive/restore, profile management
- **Validation tests** - Field types, enum values, references

See `docs/testing_strategy.md` for detailed testing documentation.

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `./scripts/build.sh` to validate
5. Run `./scripts/test.sh` to ensure tests pass
6. Submit a pull request

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
chmod +x scripts/*.sh
```

### Registry file corrupted
```bash
# Backup and recreate
cp ~/.config/claude-mcp/registry.json ~/.config/claude-mcp/registry.json.bak
./scripts/setup.sh
```

### Shell helpers not loading
```bash
# Check if sourced in shell config
grep "mcp-helpers" ~/.zshrc ~/.bashrc

# Add if missing
echo 'source ~/.config/claude-mcp/mcp-helpers.sh' >> ~/.zshrc
source ~/.zshrc
```

## License

MIT License - See LICENSE file for details.

## Related Links

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Docker MCP Catalog](https://hub.docker.com/u/mcp)
