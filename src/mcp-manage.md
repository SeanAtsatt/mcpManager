# MCP Management

You are helping the user manage their MCP (Model Context Protocol) servers interactively.

## Understanding the MCP Architecture

MCP management is **project-local** - each project has its own isolated configuration.

### Level 1: User-Configured MCPs (Project-Level)

Defined in `.mcp.json` in the project root. This controls which user-configured MCPs are available in that project.

```json
// .mcp.json - ONLY for user-configured MCP servers (command/args format)
{
  "mcpServers": {
    "project-docker-gateway": {
      "command": "docker",
      "args": ["mcp", "gateway", "run", "--config", ".docker-mcp.yaml"]
    }
  }
}
```

### Built-in MCPs (Project-Level)

Built-in MCPs like `claude-in-chrome` are configured via `.claude/settings.json`:

```json
// .claude/settings.json - for built-in MCPs
{
  "enabledMcpServers": ["claude-in-chrome"]
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
  - Project-level: Configure in `.claude/settings.json` with `enabledMcpServers` or `disabledMcpServers`
  - Global fallback: `claudeInChromeDefaultEnabled` in `~/.claude.json`

**IMPORTANT:** Built-in MCPs use `.claude/settings.json`, NOT `.mcp.json`. The `.mcp.json` file only supports the standard MCP schema (`command`/`args`), not the `enabled` flag.

## Context Files

| File | Scope | Purpose |
|------|-------|---------|
| `.mcp.json` | Project | User-configured MCP servers (command/args format only) |
| `.claude/settings.json` | Project | Built-in MCP settings (enabledMcpServers, disabledMcpServers) |
| `.docker-mcp.yaml` | Project | Docker gateway server list for this project |
| `~/.config/claude-mcp/registry.json` | Global | MCP Manager's registry - templates, profiles |
| `~/.claude.json` | Global | Fallback defaults (only if no project config) |

## Step 1: Gather Current State

Collect information from project and global sources:

1. **Project MCP config:** Read `.mcp.json` in project root (if exists)
2. **Project built-in MCP settings:** Read `.claude/settings.json` in project root (if exists)
3. **Project Docker config:** Read `.docker-mcp.yaml` in project root (if exists)
4. **Active MCPs:** Run `claude mcp list` to see currently loaded MCPs
5. **Available servers:** Use `docker mcp catalog show` or `mcp__MCP_DOCKER__mcp-find` to discover new MCPs
6. **Templates/Profiles:** Read `~/.config/claude-mcp/registry.json` for saved templates
7. **Global defaults:** Read `~/.claude.json` for fallback settings (claudeInChromeDefaultEnabled, etc.)

## Step 2: Present Status Summary

Show project context and MCP status:

```
MCP Status - Project: coherentLovingConnection
══════════════════════════════════════════════════════════════

Config Files:
  ✓ .mcp.json              User-configured MCP servers
  ✓ .claude/settings.json  Built-in MCP settings
  ✓ .docker-mcp.yaml       Docker gateway servers

User-Configured MCPs (.mcp.json):
  ✓ project-docker-gateway  Docker MCP Gateway

Built-in MCPs (.claude/settings.json):
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
  ✗ .claude/settings.json  Not found - using global defaults
  ✗ .docker-mcp.yaml       Not found

Would you like to initialize project MCP configuration?

══════════════════════════════════════════════════════════════
```

### Displaying Templates

Show saved templates in a vertical list format for better readability.

**Reading template Claude MCPs:**
- Check for `claude_mcps` field in the template
- If missing or empty `{}`, display "(none)"
- If present, list enabled MCPs: `{"claude-in-chrome": true}` → "claude-in-chrome"

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
               amazon-bedrock-agentcore, aws-cdk-mcp-server
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
1. **Initialize Project** - Create `.mcp.json`, `.claude/settings.json`, and `.docker-mcp.yaml` for this project
2. **Manage Docker MCPs** - Add/remove servers in project's `.docker-mcp.yaml`
3. **Manage Built-in MCPs** - Toggle built-in MCPs (claude-in-chrome, etc.) in `.claude/settings.json`
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
    }
  }
}
```

### Create `.claude/settings.json` (if enabling built-in MCPs):
```json
{
  "enabledMcpServers": ["claude-in-chrome"]
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

## Feature: Manage Built-in MCPs

Toggle built-in Claude Code MCPs in the project's `.claude/settings.json`.

### claude-in-chrome

To enable for this project, add to `.claude/settings.json`:
```json
{
  "enabledMcpServers": ["claude-in-chrome"]
}
```

To disable for this project (overriding global default):
```json
{
  "disabledMcpServers": ["claude-in-chrome"]
}
```

### Adding Custom MCP Servers

Custom MCP servers (not built-in) go in `.mcp.json` with the standard schema:
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

**Note:** The `.mcp.json` file only supports the standard MCP schema (`command`/`args`). Do NOT use `"enabled": true/false` syntax in `.mcp.json` - it will cause schema validation errors.

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

When user selects a template to apply, you MUST:

1. **Compare project config to template** - Check BOTH levels:
   - Docker MCPs: Compare `.docker-mcp.yaml` servers to template's `docker_mcps`
   - Built-in MCPs: Compare `.claude/settings.json` to template's `claude_mcps`

2. **Show a clear diff** - Display what will change:
   ```
   Applying template: aws-dev
   ══════════════════════════════════════════════════════════════

   Docker MCPs (.docker-mcp.yaml):
     Current: context7, aws-api, aws-documentation
     Template: context7, aws-api, aws-documentation, aws-cdk-mcp-server
     + Adding: aws-cdk-mcp-server

   Built-in MCPs (.claude/settings.json):
     Current: claude-in-chrome (enabled)
     Template: (none)
     - Removing: claude-in-chrome

   ══════════════════════════════════════════════════════════════
   ```

3. **Always ask for confirmation** - Use AskUserQuestion:
   - If there are removals, warn explicitly: "This will REMOVE claude-in-chrome"
   - If no changes needed, say "Project already matches template"
   - Never silently skip differences

4. **Apply changes only after confirmation**:
   - Update `.docker-mcp.yaml` with template's Docker MCPs
   - Update `.claude/settings.json` to match template's Built-in MCPs
   - If template has no `claude_mcps`, remove/clear `.claude/settings.json` enabledMcpServers

5. **Inform user to restart session**

Example with mismatches:
```
You: Here's what will change when applying the aws-dev template:

Docker MCPs:
  ✓ No changes (already matches)

Built-in MCPs:
  - REMOVING: claude-in-chrome

The aws-dev template does not include claude-in-chrome.
Should I apply this template and remove claude-in-chrome?

User: Yes

You: Applied aws-dev template:
  ✓ Removed claude-in-chrome from .claude/settings.json

Restart your Claude Code session for changes to take effect.
```

### Save as Template

When user wants to save current project config as a template:

1. **Get template name**: Ask for a short name (lowercase, hyphens)
   - Example: `web-dev`, `data-science`, `aws-full`

2. **Get description**: Ask for a brief description

3. **Capture current config**: Read project's `.claude/settings.json` and `.docker-mcp.yaml`

4. **Save to registry**: Add the new template to `~/.config/claude-mcp/registry.json`:

```python
import json
from datetime import datetime

# Read current registry
with open(os.path.expanduser('~/.config/claude-mcp/registry.json'), 'r') as f:
    registry = json.load(f)

# Extract Built-in MCPs from .claude/settings.json
claude_mcps = {}
settings_path = '.claude/settings.json'
if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)
    for mcp in settings.get('enabledMcpServers', []):
        claude_mcps[mcp] = True
    for mcp in settings.get('disabledMcpServers', []):
        claude_mcps[mcp] = False

# Add new template (note: use 'profiles' key, not 'templates')
registry['profiles']['<template-name>'] = {
    "description": "<user-provided-description>",
    "docker_mcps": [ ... ],      # List of servers from .docker-mcp.yaml
    "claude_mcps": claude_mcps,  # Dict of Built-in MCPs with enabled state
    "created": datetime.now().strftime('%Y-%m-%d'),
    "last_used": None
}

# Update timestamp
registry['last_updated'] = datetime.now().isoformat() + 'Z'

# Save
with open('~/.config/claude-mcp/registry.json', 'w') as f:
    json.dump(registry, f, indent=2)
```

**Template Format:**
```json
{
  "profiles": {
    "aws-dev": {
      "description": "AWS development with full tooling",
      "docker_mcps": ["context7", "aws-api", "aws-documentation"],
      "claude_mcps": {},  // Empty = no built-in MCPs
      "created": "2024-12-07"
    },
    "web-frontend": {
      "description": "Web development with browser automation",
      "docker_mcps": ["playwright", "context7"],
      "claude_mcps": {"claude-in-chrome": true},  // Includes Claude in Chrome
      "created": "2024-12-07"
    }
  }
}
```

5. **Confirm creation**: Show the user the new template details

Example interaction:
```
User: I want to save this as a template

You: I'll save your current project MCP config as a template.

Current project config:
  .mcp.json: project-docker-gateway
  .claude/settings.json: claude-in-chrome (enabled)
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
  Built-in MCPs: claude-in-chrome (enabled)
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
| `.mcp.json` | User-configured MCP servers (command/args format only) |
| `.claude/settings.json` | Built-in MCP settings (enabledMcpServers, disabledMcpServers) |
| `.docker-mcp.yaml` | Docker gateway servers |

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

  .claude/settings.json:
    - claude-in-chrome (enabled)

  .docker-mcp.yaml:
    - playwright
    - context7

Restart your Claude Code session to load the new configuration.
```
