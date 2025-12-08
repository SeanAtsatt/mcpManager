# MCP Manager

A system for dynamically managing Model Context Protocol (MCP) servers in Claude Code. Provides per-project configurations, profile management, and easy discovery of new MCPs from the Docker catalog.

## Problem Solved

Managing MCPs in Claude Code requires manual command-line operations. Users working on multiple projects with different MCP needs must manually reconfigure their setup when switching contexts. MCP Manager solves this by providing:

- **Per-project MCP configurations** (`.mcp-project.json`)
- **Profile support** for common workflow presets (aws-dev, web-frontend, etc.)
- **Interactive `/mcp-manage` slash command** for Claude Code
- **Archive management** for soft-deleting unused MCPs
- **Easy discovery** of 311+ MCP servers from the Docker catalog

## Architecture

MCP Manager works with **two levels** of MCP configuration:

1. **Claude Code MCPs** - Top-level MCPs like `MCP_DOCKER` (the Docker Gateway)
2. **Docker Gateway MCPs** - Individual servers inside the Docker Gateway (playwright, context7, aws-api, etc.)

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code                                                  │
│   └── MCP_DOCKER (Docker Gateway)                           │
│         ├── playwright        (browser automation)          │
│         ├── context7          (docs lookup)                 │
│         ├── aws-api           (AWS CLI)                     │
│         ├── aws-documentation (AWS docs)                    │
│         └── ...more servers                                 │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- [Claude Code CLI](https://claude.ai/claude-code) installed
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running
- Python 3.x
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

4. **Source the shell helpers** (add to your `~/.zshrc` or `~/.bashrc`):
   ```bash
   source ~/.config/claude-mcp/mcp-helpers.sh
   ```

5. **Verify installation:**
   ```bash
   docker mcp server ls
   ```

## Usage

### In Claude Code

#### Interactive Management
Run the `/mcp-manage` slash command:

```
/mcp-manage
```

This provides:
- **Status View** - See enabled Docker MCPs with descriptions
- **Enable/Disable** - Toggle individual MCP servers
- **Discovery** - Browse and add MCPs from Docker catalog (311+ servers)
- **Profiles** - Apply, create, or manage workflow presets
- **Archives** - View and restore archived MCPs
- **Save/Load** - Manage project configurations

### Docker MCP Commands

```bash
# List enabled servers
docker mcp server ls

# Enable a server
docker mcp server enable <name>
docker mcp server enable postgres mysql redis

# Disable a server
docker mcp server disable <name>
docker mcp server disable aws-api aws-documentation

# Search the catalog
docker mcp catalog show | grep -i <term>
```

### From Terminal

#### Interactive CLI
```bash
./scripts/run.sh
```

#### Shell Commands
```bash
mcp-status      # Show enabled MCPs
mcp-list        # List all available MCPs in registry
mcp-profiles    # List available profiles
mcp-search <term>   # Search MCPs by keyword
```

## Project Configuration

Create a `.mcp-project.json` in your project root:

```json
{
  "project": "my-project",
  "description": "Description of what this project does",
  "docker_mcps": ["playwright", "context7", "aws-api"],
  "notes": "Optional notes about this configuration"
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `project` | Yes | Project name identifier |
| `description` | No | Human-readable project description |
| `docker_mcps` | Yes | Array of Docker MCP server names to enable |
| `notes` | No | Additional notes about the configuration |

## Global Registry (v2.0 Schema)

The global registry (`~/.config/claude-mcp/registry.json`) stores MCP metadata, profiles, and archives:

```json
{
  "version": "2.0",
  "last_updated": "2024-12-07T20:00:00Z",
  "profiles": {
    "minimal": {
      "description": "Basic documentation lookup only",
      "docker_mcps": ["context7"],
      "created": "2024-12-07",
      "last_used": null
    },
    "aws-dev": {
      "description": "AWS development with full tooling",
      "docker_mcps": ["context7", "aws-api", "aws-documentation", "amazon-bedrock-agentcore"],
      "created": "2024-12-07",
      "last_used": null
    }
  },
  "docker_mcps": {
    "playwright": {
      "description": "Browser automation - navigate, click, type, take screenshots",
      "capabilities": ["Navigate to URLs", "Click elements", "Type text", "Take screenshots"],
      "tags": ["browser", "automation", "testing", "web"],
      "added": "2024-12-01"
    },
    "context7": {
      "description": "Documentation lookup - fetch latest library documentation",
      "capabilities": ["Search library docs", "Get API references", "Find code examples"],
      "tags": ["docs", "documentation", "libraries", "api"],
      "added": "2024-12-01"
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

### Docker MCP Fields

| Field | Required | Description |
|-------|----------|-------------|
| `description` | Yes | Human-readable description |
| `capabilities` | Yes | Array of specific capabilities |
| `tags` | Yes | Keywords for searching/filtering |
| `added` | No | Date MCP was added to registry |

### Profile Fields

| Field | Required | Description |
|-------|----------|-------------|
| `description` | Yes | Profile description |
| `docker_mcps` | Yes | Array of MCP server names |
| `created` | Yes | Date profile was created |
| `last_used` | No | Date profile was last applied |

## Available MCPs

### Default Docker MCPs

| Name | Description |
|------|-------------|
| `playwright` | Browser automation - navigate, click, type, screenshots |
| `context7` | Documentation lookup - fetch latest library docs |
| `aws-api` | AWS CLI execution with validation |
| `aws-documentation` | Search and read AWS documentation |
| `amazon-bedrock-agentcore` | AgentCore platform documentation |
| `aws-core-mcp-server` | Additional AWS service integrations |

### Default Profiles

| Profile | MCPs | Description |
|---------|------|-------------|
| `minimal` | context7 | Just docs lookup |
| `aws-dev` | context7, aws-api, aws-documentation, amazon-bedrock-agentcore | AWS development |
| `web-frontend` | playwright, context7 | Web development with browser |
| `full-stack` | playwright, context7, aws-api, aws-documentation, amazon-bedrock-agentcore | All common tools |
| `data-engineering` | context7, aws-api, aws-documentation | Data pipelines |

### Discovering More MCPs

The Docker MCP catalog contains 311+ servers:

```bash
# Browse the full catalog
docker mcp catalog show

# Search for specific capabilities
docker mcp catalog show | grep -i database
docker mcp catalog show | grep -i kubernetes
```

Categories include:
- **Databases** - postgres, mysql, mongodb, redis, sqlite
- **Cloud** - AWS, GCP, Azure tools
- **Documentation** - Context7, ReadTheDocs
- **Browser** - Playwright, Puppeteer
- **AI/ML** - Various AI service integrations
- **DevOps** - Docker, Kubernetes, GitHub

## Archive Management

Archives allow you to soft-delete MCPs without losing their metadata:

```
/mcp-manage > Manage Archives > Archive an MCP
/mcp-manage > Manage Archives > Restore from Archive
```

Archived MCPs are stored in the `archived` section of the registry and can be restored at any time.

## File Locations

```
~/.config/claude-mcp/
├── registry.json       # Global MCP registry (profiles, metadata, archives)
└── mcp-helpers.sh      # Shell functions for terminal management

~/.claude/commands/
└── mcp-manage.md       # /mcp-manage slash command definition

~/.docker/mcp/
└── registry.yaml       # Docker Gateway enabled servers (managed by Docker)

<project>/
├── .mcp-project.json   # Project-specific MCP configuration
└── CLAUDE.md           # Session instructions (includes MCP check)
```

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
│   ├── registry.json        # Registry template (v2.0 schema)
│   ├── mcp-helpers.sh       # Shell helpers source
│   └── mcp-manage.md        # Slash command source
└── scripts/
    ├── setup.sh             # Installation script
    ├── build.sh             # Build/validation script
    ├── test.sh              # Test runner (24 tests)
    └── run.sh               # Interactive CLI
```

### Running Tests

```bash
# Run all tests
./scripts/test.sh

# Run build validation only
./scripts/build.sh
```

### Test Coverage

The test suite (24 tests) includes:

**Unit Tests (10 tests)**
- JSON validity and schema compliance
- Required fields validation
- Profile reference validation
- Script syntax checks

**Integration Tests (8 tests)**
- Registry operations (read/write/modify)
- Archive and restore workflows
- Profile creation and deletion
- Project config handling

**Validation Tests (6 tests)**
- Field type validation
- Config section validation
- Archive section validation
- mcp-manage.md feature validation

## Troubleshooting

### MCP fails to start
1. Ensure Docker Desktop is running
2. Check the server exists: `docker mcp catalog show | grep -i <name>`
3. Try enabling manually: `docker mcp server enable <name>`

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

### Changes not taking effect
After enabling/disabling Docker MCPs, restart your Claude Code session for changes to take effect.

## License

MIT License - See LICENSE file for details.

## Related Links

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Docker MCP Catalog](https://hub.docker.com/u/mcp)
