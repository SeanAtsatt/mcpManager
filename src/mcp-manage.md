# MCP Management

You are helping the user manage their MCP (Model Context Protocol) servers interactively.

## Context Files
- **Global Registry:** `~/.config/claude-mcp/registry.json` - Master list of all known MCPs, profiles, and archives
- **Project Config:** `.mcp-project.json` in current directory (if exists)

## Step 1: Gather Current State

First, collect all relevant information:

1. Run `claude mcp list` to see currently enabled MCPs
2. Read `~/.config/claude-mcp/registry.json` for:
   - Available servers and their capabilities
   - Available profiles
   - Archived MCPs
3. Check if `.mcp-project.json` exists in the current directory

## Step 2: Present Status Summary

Display a clear status overview:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    MCP Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enabled MCPs:
  ✓ MCP_DOCKER (Docker Gateway)           ~20,000 tokens
  ✗ aws-api (AWS CLI) [available]          ~2,000 tokens
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total context usage: ~20,000 tokens

Project: my-project
Expected: MCP_DOCKER, aws-api
Status: MISMATCH - aws-api not enabled
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 3: Offer Options

Present the main menu using AskUserQuestion:

**Main Actions:**
1. **Enable/Disable MCPs** - Toggle specific MCPs on/off
2. **Apply Project Config** - Match MCPs to .mcp-project.json
3. **Discover New MCPs** - Search Docker catalog for new tools
4. **Manage Profiles** - List, apply, or create profiles
5. **Archive Management** - View/restore archived MCPs
6. **Save Configuration** - Save current state to project

## Feature: Enable/Disable MCPs

When enabling:
1. Show available MCPs from registry with descriptions
2. Show context token impact: "Adding aws-api will add ~2,000 tokens"
3. Use `claude mcp add <name> <command...>` to enable
4. Update registry `last_used` and `use_count`

When disabling:
1. Show currently enabled MCPs
2. Confirm before disabling
3. Use `claude mcp remove <name>` to disable

## Feature: Discover New MCPs

1. Ask what capabilities the user needs:
   - "What are you trying to do? (e.g., web scraping, AWS, database, AI)"

2. Search using multiple methods:
   - Use `mcp__MCP_DOCKER__mcp-find` tool if Docker Gateway is running
   - This searches the Docker MCP catalog (300+ servers)

3. Present results with:
   - Name and description
   - Capabilities list
   - Estimated context tokens
   - Tags for reference

4. Offer to:
   - Add to registry (saves for future use)
   - Enable immediately
   - Both

When adding to registry, create proper entry:
```json
{
  "status": "active",
  "source": "docker",
  "description": "...",
  "capabilities": [...],
  "command": [...],
  "context_tokens": ...,
  "tags": [...],
  "added": "YYYY-MM-DD",
  "use_count": 0
}
```

## Feature: Manage Profiles

### List Profiles
Show all profiles from registry with:
- Name and description
- MCPs included
- Last used date

### Apply Profile
1. Show what will change (MCPs to enable/disable)
2. Confirm with user
3. Disable MCPs not in profile
4. Enable MCPs in profile
5. Update profile's `last_used` date

### Create Profile
1. Get profile name from user
2. Get description
3. Save current enabled MCPs as new profile
4. Write to registry

## Feature: Archive Management

### View Archived
Show archived MCPs with:
- Name and original description
- Archive date and reason
- Last used date before archiving

### Restore from Archive
1. Show archived MCPs
2. User selects one to restore
3. Move from `archived` to `servers` section
4. Remove archive metadata
5. Offer to enable immediately

### Archive an MCP
1. Show active MCPs
2. User selects one to archive
3. Ask for reason (optional)
4. Move from `servers` to `archived` section
5. Add archive metadata (date, reason)
6. Disable if currently enabled

## Feature: Save Configuration

1. Get project name (default: directory name)
2. Get description (optional)
3. Write `.mcp-project.json`:
```json
{
  "project": "project-name",
  "description": "...",
  "enabled": ["MCP_DOCKER", "..."],
  "disabled": [],
  "notes": "Created on YYYY-MM-DD"
}
```

## Important Guidelines

1. **Always show context token estimates** - Users need to understand the cost
2. **Be conversational** - This is an interactive session, not a script
3. **Confirm destructive actions** - Before disabling or archiving
4. **Update registry timestamps** - Keep `last_updated`, `last_used`, `use_count` current
5. **Show results** - After any change, show the new state with `claude mcp list`
6. **Handle errors gracefully** - If an MCP fails to start, explain why and suggest fixes

## Example Interactions

### User wants to enable AWS tools
```
You: I see you want to work with AWS. You have two options:

1. MCP_DOCKER (already enabled) - includes AWS CLI via the gateway
   - Pro: Already using, no extra context cost
   - Con: Bundled with other tools

2. aws-api (available) - standalone AWS CLI
   - Pro: Lighter weight (~2,000 tokens vs ~20,000)
   - Con: Only AWS, no browser/docs

Which would you prefer?
```

### User discovers new MCP
```
You: I found these MCPs matching "database":

1. postgres-mcp - PostgreSQL database operations
   - Direct SQL queries, schema inspection
   - ~1,500 tokens

2. mysql-mcp - MySQL database operations
   - Query execution, table management
   - ~1,500 tokens

Would you like to add any of these to your registry?
```

## Registry Schema Reference

```json
{
  "version": "1.0",
  "last_updated": "ISO-8601 timestamp",
  "profiles": {
    "profile-name": {
      "description": "...",
      "mcps": ["mcp1", "mcp2"],
      "created": "YYYY-MM-DD",
      "last_used": "YYYY-MM-DD"
    }
  },
  "servers": {
    "mcp-name": {
      "status": "active",
      "source": "docker|docker-gateway|npx|local",
      "description": "1-2 sentence description",
      "capabilities": ["capability 1", "capability 2"],
      "command": ["cmd", "arg1", "arg2"],
      "context_tokens": 2000,
      "tags": ["tag1", "tag2"],
      "added": "YYYY-MM-DD",
      "last_used": "YYYY-MM-DD",
      "use_count": 0,
      "notes": "Optional user notes"
    }
  },
  "archived": {
    "archived-mcp": {
      "...same as servers...",
      "status": "archived",
      "archived": "YYYY-MM-DD",
      "archive_reason": "Why it was archived"
    }
  },
  "config": {
    "default_profile": null,
    "auto_apply_on_cd": false,
    "sync_with_docker_catalog": true
  }
}
```
