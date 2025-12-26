# MCP Manager

A system for dynamically managing Model Context Protocol (MCP) servers in Claude Code. Each project gets its own **isolated MCP configuration** with its own Docker gateway.

## Problem Solved

Managing MCPs in Claude Code requires manual command-line operations. Users working on multiple projects with different MCP needs must manually reconfigure their setup when switching contexts. MCP Manager solves this by providing:

- **Project-local MCP configurations** (`.mcp.json` + `.docker-mcp.yaml`)
- **Per-project Docker gateways** - Each project runs its own isolated gateway
- **Template support** for reusable MCP presets across projects
- **Claude Code MCP management** (claude-in-chrome, custom MCPs)
- **Interactive `/mcp-manage` slash command** for Claude Code
- **Archive management** for soft-deleting unused MCPs
- **Easy discovery** of 311+ MCP servers from the Docker catalog

## Architecture

MCP management is **project-local** - each project has its own isolated configuration.

### Level 1: Claude Code MCPs (Project-Level)

Defined in `.mcp.json` in the project root:

```json
{
  "mcpServers": {
    "project-docker-gateway": {
      "command": "docker",
      "args": ["mcp", "gateway", "run", "--config", ".docker-mcp.yaml"]
    },
    "claude-in-chrome": {
      "enabled": true
    }
  }
}
```

### Level 2: Docker Gateway MCPs (Project-Level)

Defined in `.docker-mcp.yaml` in the project root:

```yaml
servers:
  - playwright
  - context7
  - aws-api
```

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Project A                         Project B                  │
│                                                              │
│   .mcp.json ──┐                   .mcp.json ──┐             │
│               ▼                               ▼             │
│   ┌─────────────────┐           ┌─────────────────┐        │
│   │  Docker Gateway │           │  Docker Gateway │        │
│   │  (Project A)    │           │  (Project B)    │        │
│   │                 │           │                 │        │
│   │  playwright     │           │  aws-api        │        │
│   │  context7       │           │  aws-docs       │        │
│   └─────────────────┘           └─────────────────┘        │
│                                                              │
│   .docker-mcp.yaml              .docker-mcp.yaml            │
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
- **Initialize Project** - Create `.mcp.json` and `.docker-mcp.yaml` for this project
- **Manage Docker MCPs** - Add/remove servers in project's `.docker-mcp.yaml`
- **Manage Claude Code MCPs** - Toggle claude-in-chrome and other MCPs in `.mcp.json`
- **Discover New MCPs** - Browse and add MCPs from Docker catalog (311+ servers)
- **Manage Templates** - Save current config as template, apply templates to projects
- **Manage Archives** - View and restore archived MCPs

#### Session Commands

| Command | Purpose |
|---------|---------|
| `/startup` | Initialize session - reads project, checks MCPs, starts gateway, reports issues |
| `/shutdown` | End session - stops gateway, offers to commit changes |
| `/project-update` | Fix detected issues - migrates config schema, cleans up files |

**Recommended workflow:**
1. Run `/startup` at the beginning of each session
2. If issues detected, run `/project-update` to fix them
3. Run `/shutdown` when ending the session

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

Each project needs two config files in the project root:

### `.mcp.json` - Claude Code MCPs

```json
{
  "mcpServers": {
    "project-docker-gateway": {
      "command": "docker",
      "args": ["mcp", "gateway", "run", "--config", ".docker-mcp.yaml"]
    },
    "claude-in-chrome": {
      "enabled": true
    }
  }
}
```

### `.docker-mcp.yaml` - Docker Gateway Servers

```yaml
# Docker MCP Gateway servers for this project
servers:
  - playwright
  - context7
  - aws-api
```

### Configuration Fields

#### `.mcp.json` mcpServers

| Key | Description |
|-----|-------------|
| `project-docker-gateway` | Docker gateway config pointing to `.docker-mcp.yaml` |
| `claude-in-chrome` | Browser automation - set `enabled: true/false` |
| Custom MCPs | Any additional MCP server definitions |

#### `.docker-mcp.yaml`

| Field | Required | Description |
|-------|----------|-------------|
| `servers` | Yes | Array of Docker MCP server names to enable |

### Migration from Old Format

If you have an old `.mcp-project.json`, run `/mcp-manage` to migrate to the new format:

| Old Format | New Format |
|------------|------------|
| `.mcp-project.json` | `.mcp.json` + `.docker-mcp.yaml` |
| `docker_mcps: [...]` | `servers:` in `.docker-mcp.yaml` |

## Multi-Project Support

With the new project-local architecture, **each project automatically gets its own isolated gateway**. No port configuration needed - Claude Code handles isolation via the project's `.mcp.json`.

### How It Works

1. **Create project config**: Add `.mcp.json` and `.docker-mcp.yaml` to your project
2. **Start Claude Code session**: The gateway starts automatically from the project config
3. **Work independently**: Each project has its own isolated MCP tools
4. **Switch projects**: Each project loads its own config when you start a session there

### Example Setup

**Project A** (Web development):

`.mcp.json`:
```json
{
  "mcpServers": {
    "project-docker-gateway": {
      "command": "docker",
      "args": ["mcp", "gateway", "run", "--config", ".docker-mcp.yaml"]
    },
    "claude-in-chrome": { "enabled": true }
  }
}
```

`.docker-mcp.yaml`:
```yaml
servers:
  - playwright
  - context7
```

**Project B** (AWS infrastructure):

`.mcp.json`:
```json
{
  "mcpServers": {
    "project-docker-gateway": {
      "command": "docker",
      "args": ["mcp", "gateway", "run", "--config", ".docker-mcp.yaml"]
    }
  }
}
```

`.docker-mcp.yaml`:
```yaml
servers:
  - aws-api
  - aws-documentation
  - context7
```

### Key Points

- **Automatic Isolation**: Each project has its own gateway via `.mcp.json`
- **No Port Management**: Claude Code handles transport automatically
- **Catalog Access**: All projects can discover from the Docker MCP catalog (311+ servers)
- **Session Lifecycle**: Gateway starts/stops with your Claude Code session

## Global Registry

The global registry (`~/.config/claude-mcp/registry.json`) stores **templates** for reuse across projects, MCP metadata, and archives:

```json
{
  "version": "2.0",
  "last_updated": "2024-12-07T20:00:00Z",
  "templates": {
    "minimal": {
      "description": "Basic documentation lookup only",
      "mcp_json": { ... },
      "docker_mcp_yaml": ["context7"],
      "created": "2024-12-07"
    },
    "web-frontend": {
      "description": "Web development with browser automation",
      "mcp_json": { ... },
      "docker_mcp_yaml": ["playwright", "context7"],
      "created": "2024-12-07"
    },
    "aws-dev": {
      "description": "AWS development with full tooling",
      "mcp_json": { ... },
      "docker_mcp_yaml": ["context7", "aws-api", "aws-documentation", "amazon-bedrock-agentcore"],
      "created": "2024-12-07"
    }
  },
  "docker_mcps": {
    "playwright": {
      "description": "Browser automation - navigate, click, type, take screenshots",
      "capabilities": ["Navigate to URLs", "Click elements", "Type text", "Take screenshots"],
      "tags": ["browser", "automation", "testing", "web"]
    },
    "context7": {
      "description": "Documentation lookup - fetch latest library documentation",
      "capabilities": ["Search library docs", "Get API references", "Find code examples"],
      "tags": ["docs", "documentation", "libraries", "api"]
    }
  },
  "archived": {}
}
```

### Template Fields

| Field | Required | Description |
|-------|----------|-------------|
| `description` | Yes | Template description |
| `mcp_json` | Yes | Contents for `.mcp.json` |
| `docker_mcp_yaml` | Yes | Server list for `.docker-mcp.yaml` |
| `created` | Yes | Date template was created |

### Docker MCP Fields

| Field | Required | Description |
|-------|----------|-------------|
| `description` | Yes | Human-readable description |
| `capabilities` | Yes | Array of specific capabilities |
| `tags` | Yes | Keywords for searching/filtering |

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

### Default Templates

| Template | Docker MCPs | Claude MCPs | Description |
|----------|-------------|-------------|-------------|
| `minimal` | context7 | (none) | Just docs lookup |
| `web-frontend` | playwright, context7 | claude-in-chrome | Web development with browser |
| `aws-dev` | context7, aws-api, aws-documentation, amazon-bedrock-agentcore | (none) | AWS development |
| `full-stack` | playwright, context7, aws-api, aws-documentation, amazon-bedrock-agentcore | claude-in-chrome | All common tools |

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
<project>/                    # Project-local (primary)
├── .mcp.json                 # Claude Code MCPs for this project
├── .docker-mcp.yaml          # Docker gateway servers for this project
└── CLAUDE.md                 # Session instructions

~/.config/claude-mcp/         # Global (templates & metadata)
├── registry.json             # Templates, MCP metadata, archives
└── mcp-helpers.sh            # Shell functions for terminal management

~/.claude/commands/           # Slash commands
└── mcp-manage.md             # /mcp-manage slash command definition

~/.claude.json                # Global fallback defaults
```

## Development

### Project Structure

```
mcpManager/
├── README.md                 # This file
├── CLAUDE.md                 # Claude Code session instructions
├── .mcp.json                 # Claude Code MCPs for this project
├── .docker-mcp.yaml          # Docker gateway servers for this project
├── docs/
│   ├── PRD.md               # Product Requirements Document
│   └── testing_strategy.md  # Testing documentation
├── src/
│   ├── registry.json        # Registry template (v2.0 schema)
│   ├── mcp-helpers.sh       # Shell helpers source
│   ├── mcp-manage.md        # /mcp-manage slash command
│   ├── startup.md           # /startup slash command
│   ├── shutdown.md          # /shutdown slash command
│   └── project-update.md    # /project-update slash command
└── scripts/
    ├── setup.sh             # Installation script
    ├── build.sh             # Build/validation script
    ├── test.sh              # Test runner (auto-numbered)
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

The test suite validates the new project-local architecture:

**Unit Tests**
- JSON/YAML validity and schema compliance
- Required fields validation
- Template reference validation
- Script syntax checks
- Slash command validation (mcp-manage.md, startup.md, shutdown.md, project-update.md)

**Integration Tests**
- Registry operations (read/write/modify)
- Archive and restore workflows
- Template creation and application
- Project config handling (.mcp.json + .docker-mcp.yaml)
- Migration from old format (.mcp-project.json → .mcp.json + .docker-mcp.yaml)

**Validation Tests**
- Field type validation
- Template section validation
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
After modifying `.mcp.json` or `.docker-mcp.yaml`, restart your Claude Code session for changes to take effect.

### Missing project config
If `.mcp.json` or `.docker-mcp.yaml` don't exist, run `/mcp-manage` and select "Initialize Project" to create them.

## License

MIT License - See LICENSE file for details.

## Related Links

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Docker MCP Catalog](https://hub.docker.com/u/mcp)
