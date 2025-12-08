# MCP Management

You are helping the user manage their MCP (Model Context Protocol) servers interactively.

## Understanding the MCP Architecture

There are TWO levels of MCP management:

1. **Claude Code MCPs** (`claude mcp list`) - Top-level MCPs like `MCP_DOCKER`
2. **Docker Gateway MCPs** (`~/.docker/mcp/registry.yaml`) - Individual servers INSIDE the Docker Gateway

The Docker Gateway (`MCP_DOCKER`) is a container that bundles multiple MCP servers. Users can enable/disable individual servers within the gateway.

## Context Files

| File | Purpose |
|------|---------|
| `~/.docker/mcp/registry.yaml` | **Docker Gateway enabled servers** - Individual MCPs inside the gateway |
| `~/.config/claude-mcp/registry.json` | MCP Manager's registry - metadata, profiles, archives |
| `.mcp-project.json` | Project-specific MCP configuration |

## Step 1: Gather Current State

Collect information from ALL sources:

1. **Claude Code level:** Run `claude mcp list` to see top-level MCPs
2. **Docker Gateway level:** Read `~/.docker/mcp/registry.yaml` to see individual enabled servers
3. **Available servers:** Use `docker mcp catalog show` or `mcp__MCP_DOCKER__mcp-find` to see what's available
4. **Registry metadata:** Read `~/.config/claude-mcp/registry.json` for profiles and archives
5. **Project config:** Check if `.mcp-project.json` exists

## Step 2: Present Status Summary

Show the Docker Gateway servers in a clean, wrapped format:

```
MCP Status
══════════════════════════════════════════════════════════════

Claude Code: MCP_DOCKER (Docker Gateway) ✓ Connected

Docker Gateway Servers:
  ✓ playwright                Browser automation
  ✓ context7                  Documentation lookup
  ✓ aws-api                   AWS CLI execution
  ✓ aws-documentation         AWS docs search
  ✓ amazon-bedrock-agentcore  AgentCore docs
  ✓ aws-core-mcp-server       AWS core tools

══════════════════════════════════════════════════════════════
```

### Displaying Profiles

Show profiles in a vertical list format for better readability:

```
Available Profiles:
───────────────────

minimal
  Description: Basic documentation lookup only
  MCPs: context7

aws-dev
  Description: AWS development with full tooling
  MCPs: context7, aws-api, aws-documentation,
        amazon-bedrock-agentcore

web-frontend
  Description: Web development with browser automation
  MCPs: playwright, context7

full-stack
  Description: Full stack development with all common tools
  MCPs: playwright, context7, aws-api, aws-documentation,
        amazon-bedrock-agentcore
```

## Step 3: Offer Options

Present the main menu using AskUserQuestion:

**Main Actions:**
1. **Enable/Disable Docker MCPs** - Toggle individual servers in the Docker Gateway
2. **Discover New MCPs** - Search Docker catalog for new tools
3. **Manage Profiles** - List, apply, or CREATE new profiles
4. **Manage Archives** - View and restore archived MCPs
5. **Save/Load Project Config** - Manage .mcp-project.json

## Feature: Enable/Disable Docker MCPs

### To ENABLE a server in Docker Gateway:
```bash
docker mcp server enable <server-name>
# Or enable multiple at once:
docker mcp server enable <name1> <name2> <name3>
```

### To DISABLE a server in Docker Gateway:
```bash
docker mcp server disable <server-name>
# Or disable multiple at once:
docker mcp server disable <name1> <name2> <name3>
```

### To LIST currently enabled servers:
```bash
docker mcp server ls
```

### After changes:
The Docker Gateway needs to be restarted. User should restart their Claude Code session for changes to take effect.

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

## Feature: Manage Profiles

When user selects "Manage Profiles", offer these sub-options:

1. **List Profiles** - Show all available profiles with their MCPs
2. **Apply Profile** - Switch to a different profile
3. **Create New Profile** - Save current MCPs as a new profile

### List Profiles
Display each profile vertically with wrapped MCP lists (see format above).

### Apply Profile
1. Show current MCPs vs profile MCPs
2. Show what will be added/removed
3. Confirm with user
4. Run `docker mcp server enable/disable` commands
5. Inform user to restart session

### Create New Profile (IMPORTANT)

When user wants to create a new profile:

1. **Get profile name**: Ask for a short name (lowercase, no spaces, use hyphens)
   - Example: `my-project`, `data-science`, `frontend-dev`

2. **Get description**: Ask for a brief description of the profile's purpose

3. **Capture current MCPs**: Read `~/.docker/mcp/registry.yaml` to get the list of currently enabled servers

4. **Save to registry**: Add the new profile to `~/.config/claude-mcp/registry.json`:

```python
import json
from datetime import datetime

# Read current registry
with open('~/.config/claude-mcp/registry.json', 'r') as f:
    registry = json.load(f)

# Add new profile
registry['profiles']['<profile-name>'] = {
    "description": "<user-provided-description>",
    "docker_mcps": ["<list>", "<of>", "<current>", "<mcps>"],
    "created": datetime.now().strftime('%Y-%m-%d'),
    "last_used": None
}

# Update timestamp
registry['last_updated'] = datetime.now().isoformat() + 'Z'

# Save
with open('~/.config/claude-mcp/registry.json', 'w') as f:
    json.dump(registry, f, indent=2)
```

5. **Confirm creation**: Show the user the new profile details

Example interaction:
```
User: I want to create a new profile

You: I'll help you create a new profile from your current MCP setup.

Current enabled MCPs:
  - playwright
  - context7
  - aws-api
  - postgres

What would you like to name this profile?
(Use lowercase with hyphens, e.g., "my-project", "data-work")

User: backend-api

You: Great! Now give me a brief description for "backend-api":

User: Backend API development with database and AWS

You: Perfect! I've created the profile:

  Profile: backend-api
  Description: Backend API development with database and AWS
  MCPs: playwright, context7, aws-api, postgres
  Created: 2024-12-07

The profile has been saved to your registry. You can apply it anytime
with /mcp-manage > Manage Profiles > Apply Profile.
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

## Feature: Save/Load Project Config

### Save to Project
1. Read `~/.docker/mcp/registry.yaml` for enabled MCPs
2. Write `.mcp-project.json`:
```json
{
  "project": "project-name",
  "description": "Project description",
  "docker_mcps": ["playwright", "context7", "aws-api"],
  "notes": "Created YYYY-MM-DD"
}
```

### Load from Project
1. Read `.mcp-project.json`
2. Compare with `~/.docker/mcp/registry.yaml`
3. Show diff and offer to apply changes

## Important Guidelines

1. **Use vertical layouts** - List profiles and MCPs vertically, not in tables
2. **Wrap long lists** - If MCP list is long, wrap to multiple lines with proper indentation
3. **Show BOTH levels** - Claude Code MCPs AND Docker Gateway servers
4. **Be specific about commands** - Show exact `docker mcp server enable/disable` commands
5. **Explain restart requirements** - Changes need session restart
6. **Confirm destructive actions** - Before removing servers

## Docker MCP Commands Reference

| Command | Purpose |
|---------|---------|
| `docker mcp catalog show` | List all 311+ available servers |
| `docker mcp server enable <name>` | Enable a server in the gateway |
| `docker mcp server disable <name>` | Disable a server from the gateway |
| `docker mcp server ls` | List currently enabled servers |
| `cat ~/.docker/mcp/registry.yaml` | See enabled servers (config file) |

## Example: Creating a Profile

```
You: I'll create a new profile from your current setup.

Your currently enabled MCPs:
  - playwright
  - context7
  - aws-api
  - aws-documentation

What would you like to name this profile?

User: web-api-dev

You: Description for "web-api-dev"?

User: Web API development with browser testing

You: Created profile "web-api-dev":

  web-api-dev
    Description: Web API development with browser testing
    MCPs: playwright, context7, aws-api, aws-documentation
    Created: 2024-12-07

Profile saved! Use /mcp-manage to apply it anytime.
```
