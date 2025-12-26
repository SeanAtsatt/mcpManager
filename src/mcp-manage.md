# MCP Management

You are helping the user manage their MCP (Model Context Protocol) servers interactively.

## Understanding the MCP Architecture

MCP management is **project-local** - each project has its own isolated configuration.

### Level 1: Claude Code MCPs (Project-Level)

Defined in `.mcp.json` in the project root. This controls which MCPs are available in that project.

```json
// .mcp.json
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

Each project can have its own Docker gateway with its own set of MCPs.

| File | Purpose |
|------|---------|
| `.mcp.json` | Defines the project's Docker gateway |
| `.docker-mcp.yaml` | Lists which MCPs run in this project's gateway |

Example `.docker-mcp.yaml`:
```yaml
servers:
  - playwright
  - context7
  - aws-api
```

### Built-in Claude Code MCPs

Some MCPs are built into Claude Code:
- **claude-in-chrome** - Browser automation via Chrome extension
  - Project-level: Add to `.mcp.json` with `"enabled": true/false`
  - Global fallback: `claudeInChromeDefaultEnabled` in `~/.claude.json`

## Context Files

| File | Scope | Purpose |
|------|-------|---------|
| `.mcp.json` | Project | **Primary config** - Claude Code MCPs for this project |
| `.docker-mcp.yaml` | Project | Docker gateway server list for this project |
| `~/.config/claude-mcp/registry.json` | Global | MCP Manager's registry - templates, profiles |
| `~/.claude.json` | Global | Fallback defaults (only if no project config) |

## Step 1: Gather Current State

Collect information from project and global sources:

1. **Project MCP config:** Read `.mcp.json` in project root (if exists)
2. **Project Docker config:** Read `.docker-mcp.yaml` in project root (if exists)
3. **Active MCPs:** Run `claude mcp list` to see currently loaded MCPs
4. **Available servers:** Use `docker mcp catalog show` or `mcp__MCP_DOCKER__mcp-find` to discover new MCPs
5. **Templates/Profiles:** Read `~/.config/claude-mcp/registry.json` for saved templates
6. **Global defaults:** Read `~/.claude.json` for fallback settings (claudeInChromeDefaultEnabled, etc.)

## Step 2: Present Status Summary

Show project context and MCP status:

```
MCP Status - Project: coherentLovingConnection
══════════════════════════════════════════════════════════════

Config Files:
  ✓ .mcp.json              Project MCP configuration
  ✓ .docker-mcp.yaml       Docker gateway servers

Claude Code MCPs:
  ✓ project-docker-gateway  Docker MCP Gateway
  ✓ claude-in-chrome        Browser automation (enabled)

Docker Gateway Servers (.docker-mcp.yaml):
  ✓ playwright              Browser automation
  ✓ context7                Documentation lookup
  ✓ aws-api                 AWS CLI execution

══════════════════════════════════════════════════════════════
```

If no project config exists, show:
```
MCP Status - Project: myproject
══════════════════════════════════════════════════════════════

Config Files:
  ✗ .mcp.json              Not found - using global defaults
  ✗ .docker-mcp.yaml       Not found

Would you like to initialize project MCP configuration?

══════════════════════════════════════════════════════════════
```

### Displaying Templates

Show saved templates in a vertical list format for better readability:

```
Available Templates:
────────────────────

minimal
  Description: Basic documentation lookup only
  Docker MCPs: context7
  Claude MCPs: (none)

aws-dev
  Description: AWS development with full tooling
  Docker MCPs: context7, aws-api, aws-documentation,
               amazon-bedrock-agentcore
  Claude MCPs: (none)

web-frontend
  Description: Web development with browser automation
  Docker MCPs: playwright, context7
  Claude MCPs: claude-in-chrome

full-stack
  Description: Full stack development with all common tools
  Docker MCPs: playwright, context7, aws-api, aws-documentation,
               amazon-bedrock-agentcore
  Claude MCPs: claude-in-chrome
```

## Step 3: Offer Options

Present the main menu using AskUserQuestion:

**Main Actions:**
1. **Initialize Project** - Create `.mcp.json` and `.docker-mcp.yaml` for this project
2. **Manage Docker MCPs** - Add/remove servers in project's `.docker-mcp.yaml`
3. **Manage Claude Code MCPs** - Toggle built-in MCPs (claude-in-chrome, etc.) in `.mcp.json`
4. **Discover New MCPs** - Search Docker catalog for new tools
5. **Manage Templates** - Save current config as template, apply templates
6. **Manage Archives** - View and restore archived MCPs

## Feature: Initialize Project

Create project-local MCP configuration files:

### Create `.mcp.json`:
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

### Create `.docker-mcp.yaml`:
```yaml
# Docker MCP Gateway servers for this project
servers:
  - context7
  - playwright
```

### After initialization:
User should restart their Claude Code session to load the new project config.

## Feature: Manage Docker MCPs

Edit the project's `.docker-mcp.yaml` to add/remove servers.

### To ADD a server:
Add the server name to the `servers` list in `.docker-mcp.yaml`

### To REMOVE a server:
Remove the server name from the `servers` list in `.docker-mcp.yaml`

### To see available servers:
```bash
docker mcp catalog show
```
Or use `mcp__MCP_DOCKER__mcp-find` tool with a search query.

### After changes:
User should restart their Claude Code session for changes to take effect.

## Feature: Manage Claude Code MCPs

Toggle built-in Claude Code MCPs in the project's `.mcp.json`.

### claude-in-chrome

To enable for this project:
```json
// In .mcp.json mcpServers section:
"claude-in-chrome": {
  "enabled": true
}
```

To disable for this project:
```json
"claude-in-chrome": {
  "enabled": false
}
```

### Other Claude Code MCPs

Any MCP can be added to the project's `.mcp.json`:
```json
{
  "mcpServers": {
    "custom-mcp": {
      "command": "node",
      "args": ["/path/to/mcp-server.js"]
    }
  }
}
```

## Feature: Discover New MCPs

1. Ask what capabilities the user needs
2. Search the Docker catalog (311+ servers available):
   - Use `mcp__MCP_DOCKER__mcp-find` tool with a search query
   - Or run `docker mcp catalog show | grep -i <term>`
3. Present results with descriptions
4. Offer to add to the Docker Gateway

### Common Categories:
- **Databases:** postgres, mysql, mongodb, redis, sqlite
- **Cloud:** aws-api, aws-documentation, aws-cdk-mcp-server
- **Browser:** playwright
- **Documentation:** context7, astro-docs, atlas-docs
- **AI/ML:** amazon-bedrock-agentcore, anthropic
- **DevOps:** docker, kubernetes, github

## Feature: Manage Templates

Templates let you save and reuse MCP configurations across projects.

When user selects "Manage Templates", offer these sub-options:

1. **List Templates** - Show all saved templates
2. **Apply Template** - Apply a template to this project's config files
3. **Save as Template** - Save current project's config as a new template

### List Templates
Display each template vertically with their MCPs.

### Apply Template
1. Show what the template contains
2. Confirm with user
3. Write template contents to `.mcp.json` and `.docker-mcp.yaml`
4. Inform user to restart session

### Save as Template

When user wants to save current project config as a template:

1. **Get template name**: Ask for a short name (lowercase, hyphens)
   - Example: `web-dev`, `data-science`, `aws-full`

2. **Get description**: Ask for a brief description

3. **Capture current config**: Read project's `.mcp.json` and `.docker-mcp.yaml`

4. **Save to registry**: Add the new template to `~/.config/claude-mcp/registry.json`:

```python
import json
from datetime import datetime

# Read current registry
with open(os.path.expanduser('~/.config/claude-mcp/registry.json'), 'r') as f:
    registry = json.load(f)

# Add new template
registry['templates']['<template-name>'] = {
    "description": "<user-provided-description>",
    "mcp_json": { ... },  # Contents of .mcp.json
    "docker_mcp_yaml": [ ... ],  # List of servers from .docker-mcp.yaml
    "created": datetime.now().strftime('%Y-%m-%d')
}

# Update timestamp
registry['last_updated'] = datetime.now().isoformat() + 'Z'

# Save
with open('~/.config/claude-mcp/registry.json', 'w') as f:
    json.dump(registry, f, indent=2)
```

5. **Confirm creation**: Show the user the new template details

Example interaction:
```
User: I want to save this as a template

You: I'll save your current project MCP config as a template.

Current project config:
  .mcp.json: project-docker-gateway, claude-in-chrome
  .docker-mcp.yaml: playwright, context7, aws-api, postgres

What would you like to name this template?
(Use lowercase with hyphens, e.g., "web-dev", "data-work")

User: backend-api

You: Great! Now give me a brief description for "backend-api":

User: Backend API development with database and AWS

You: Perfect! I've created the template:

  Template: backend-api
  Description: Backend API development with database and AWS
  Docker MCPs: playwright, context7, aws-api, postgres
  Claude MCPs: claude-in-chrome (enabled)
  Created: 2024-12-07

The template has been saved. You can apply it to any project
with /mcp-manage > Manage Templates > Apply Template.
```

## Feature: Manage Archives

Archives allow you to soft-delete MCPs you're not using without losing their metadata. Archived MCPs can be restored later.

The `archived` section in `~/.config/claude-mcp/registry.json` stores archived MCP metadata.

When user selects "Manage Archives", offer these sub-options:

1. **View Archived MCPs** - Show all archived MCPs with their details
2. **Archive an MCP** - Move an MCP to archives (soft delete)
3. **Restore from Archive** - Bring back an archived MCP

### View Archived MCPs

Display archived MCPs in vertical format:

```
Archived MCPs:
──────────────

postgres
  Description: PostgreSQL database operations
  Archived: 2024-12-01
  Reason: Not needed for current projects

redis
  Description: Redis cache operations
  Archived: 2024-11-15
  Reason: Switched to in-memory caching

(No archived MCPs)  ← if archive is empty
```

### Archive an MCP

When archiving an MCP:

1. **Select MCP to archive**: Show list of MCPs in `docker_mcps` section
2. **Get reason** (optional): Ask why they're archiving it
3. **Disable if enabled**: Run `docker mcp server disable <name>` if currently enabled
4. **Move to archived section**: Update registry.json

```python
import json
from datetime import datetime

with open('~/.config/claude-mcp/registry.json', 'r') as f:
    registry = json.load(f)

# Get the MCP data
mcp_name = "<selected-mcp>"
mcp_data = registry['docker_mcps'].pop(mcp_name)

# Add archive metadata
mcp_data['archived_date'] = datetime.now().strftime('%Y-%m-%d')
mcp_data['archive_reason'] = "<user-provided-reason>"

# Move to archived section
registry['archived'][mcp_name] = mcp_data
registry['last_updated'] = datetime.now().isoformat() + 'Z'

with open('~/.config/claude-mcp/registry.json', 'w') as f:
    json.dump(registry, f, indent=2)
```

### Restore from Archive

When restoring an MCP:

1. **Select archived MCP**: Show list from `archived` section
2. **Move back to docker_mcps**: Remove archive metadata, move to main section
3. **Offer to enable**: Ask if user wants to enable it now

```python
import json
from datetime import datetime

with open('~/.config/claude-mcp/registry.json', 'r') as f:
    registry = json.load(f)

# Get archived MCP
mcp_name = "<selected-mcp>"
mcp_data = registry['archived'].pop(mcp_name)

# Remove archive metadata
mcp_data.pop('archived_date', None)
mcp_data.pop('archive_reason', None)

# Move back to main section
registry['docker_mcps'][mcp_name] = mcp_data
registry['last_updated'] = datetime.now().isoformat() + 'Z'

with open('~/.config/claude-mcp/registry.json', 'w') as f:
    json.dump(registry, f, indent=2)
```

Then if user wants to enable:
```bash
docker mcp server enable <mcp-name>
```

### Example: Archiving an MCP

```
You: Which MCP would you like to archive?

Current MCPs:
  - playwright
  - context7
  - aws-api
  - aws-documentation
  - amazon-bedrock-agentcore
  - aws-core-mcp-server

User: aws-core-mcp-server

You: Why are you archiving aws-core-mcp-server? (optional, press enter to skip)

User: Rarely used, cleaning up

You: Archived "aws-core-mcp-server":

  aws-core-mcp-server
    Description: AWS core tools
    Archived: 2024-12-07
    Reason: Rarely used, cleaning up

The MCP has been disabled and moved to archives.
You can restore it anytime with /mcp-manage > Manage Archives > Restore.
```

### Example: Restoring from Archive

```
You: Which archived MCP would you like to restore?

Archived MCPs:
  - aws-core-mcp-server (archived 2024-12-07)
  - postgres (archived 2024-11-15)

User: postgres

You: Restored "postgres" from archives.

Would you like to enable it now?

User: Yes

You: Running: docker mcp server enable postgres

Done! Restart your Claude Code session to use postgres.
```

## Important Guidelines

1. **Project-local first** - Always work with `.mcp.json` and `.docker-mcp.yaml` in project root
2. **Use vertical layouts** - List templates and MCPs vertically, not in tables
3. **Wrap long lists** - If MCP list is long, wrap to multiple lines with proper indentation
4. **Show BOTH levels** - Claude Code MCPs (from .mcp.json) AND Docker Gateway servers (from .docker-mcp.yaml)
5. **Explain restart requirements** - Changes to config files need session restart
6. **Confirm destructive actions** - Before removing servers or overwriting configs

## Commands Reference

### Claude Code MCP Commands
| Command | Purpose |
|---------|---------|
| `claude mcp list` | List active MCPs in current session |
| `claude mcp add <name> --scope project` | Add MCP to project's .mcp.json |
| `claude mcp remove <name>` | Remove MCP from config |

### Docker MCP Commands
| Command | Purpose |
|---------|---------|
| `docker mcp catalog show` | List all 311+ available servers |
| `docker mcp server ls` | List servers in global gateway |

### Project Config Files
| File | Purpose |
|------|---------|
| `.mcp.json` | Project's Claude Code MCPs |
| `.docker-mcp.yaml` | Project's Docker gateway servers |

## Example: Initializing a New Project

```
You: This project doesn't have MCP configuration yet.
     Would you like me to initialize it?

User: Yes

You: I'll create the project MCP config files.

What Docker MCPs do you need? (You can search with /mcp-manage later)
Common choices: playwright, context7, aws-api

User: playwright and context7

You: Enable claude-in-chrome for browser automation?

User: Yes

You: Created project MCP configuration:

  .mcp.json:
    - project-docker-gateway (Docker MCP Gateway)
    - claude-in-chrome (enabled)

  .docker-mcp.yaml:
    - playwright
    - context7

Restart your Claude Code session to load the new configuration.
```
