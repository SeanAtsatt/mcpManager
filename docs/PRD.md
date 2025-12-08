# MCP Manager - Product Requirements Document

## Overview

MCP Manager is a system for dynamically managing Model Context Protocol (MCP) servers in Claude Code. It provides both global defaults and per-project configurations, allowing users to quickly switch between different MCP setups based on project needs.

## Problem Statement

Currently, managing MCPs in Claude Code requires manual command-line operations (`claude mcp add/remove`). Users working on multiple projects with different MCP needs must manually reconfigure their setup when switching contexts. There's no way to:
- Save MCP configurations per project
- Share MCP setups across machines or with team members
- Quickly discover and add new MCPs from available catalogs
- Create reusable "profiles" for common workflows

## Goals

1. **Simplify MCP management** - Single `/mcp-manage` command for all MCP operations
2. **Enable per-project configs** - Automatically detect and apply project-specific MCP settings
3. **Support global defaults** - Maintain user-wide MCP preferences that apply when no project config exists
4. **Enable discovery** - Browse and add MCPs from Docker catalog and other sources
5. **Support profiles** - Create named presets (e.g., "aws-dev", "web-frontend") for quick switching

## Architecture

### File Locations

| File | Location | Purpose |
|------|----------|---------|
| Global Registry | `~/.config/claude-mcp/registry.json` | Master list of all known MCPs with their commands and metadata |
| Global Helpers | `~/.config/claude-mcp/mcp-helpers.sh` | Shell functions for terminal-based MCP management |
| Project Config | `.mcp-project.json` (project root) | Project-specific enabled/disabled MCPs and profiles |
| Slash Command | `~/.claude/commands/mcp-manage.md` | The `/mcp-manage` command definition |
| Session Instructions | `CLAUDE.md` (project root) | Auto-loaded instructions including MCP check on session start |

### Data Structures

#### Global Registry (`~/.config/claude-mcp/registry.json`)

The registry is the **single source of truth** for all MCPs. It contains:
- **Every MCP ever used** - nothing is ever deleted, only archived
- **Active servers** - MCPs available for use
- **Archived servers** - MCPs previously used but currently disabled (can be restored)
- **Rich descriptions** - Detailed info to make intelligent decisions about which MCPs to enable

```json
{
  "version": "1.0",
  "last_updated": "2024-12-07T19:00:00Z",
  "profiles": {
    "aws-dev": {
      "description": "AWS development with full tooling",
      "mcps": ["MCP_DOCKER", "aws-api"],
      "created": "2024-12-07",
      "last_used": "2024-12-07"
    },
    "web-frontend": {
      "description": "Web development with browser automation",
      "mcps": ["MCP_DOCKER", "playwright"],
      "created": "2024-12-07",
      "last_used": null
    },
    "minimal": {
      "description": "Just Context7 for docs lookup",
      "mcps": ["MCP_DOCKER"],
      "created": "2024-12-07",
      "last_used": null
    }
  },
  "servers": {
    "MCP_DOCKER": {
      "status": "active",
      "source": "docker-gateway",
      "description": "Docker MCP Gateway - A unified gateway that bundles multiple MCP servers including browser automation (Playwright), documentation lookup (Context7), AWS tools, and more. This is the recommended default for most projects.",
      "capabilities": [
        "Browser automation via Playwright (navigate, click, type, screenshot)",
        "Documentation lookup via Context7 (fetch latest library docs)",
        "AWS CLI execution with validation",
        "AgentCore documentation search",
        "Code execution in sandboxed environments"
      ],
      "command": ["docker", "mcp", "gateway", "run"],
      "context_tokens": 20000,
      "tags": ["browser", "docs", "aws", "context7", "gateway"],
      "added": "2024-12-01",
      "last_used": "2024-12-07",
      "use_count": 42,
      "notes": "Primary gateway - includes most common tools"
    },
    "aws-api": {
      "status": "active",
      "source": "docker",
      "description": "Standalone AWS CLI MCP server. Executes AWS CLI commands with validation and proper error handling. Use this for dedicated AWS work when you don't need the full Docker Gateway overhead.",
      "capabilities": [
        "Execute any AWS CLI command",
        "Command validation before execution",
        "Support for all AWS services",
        "Region and profile configuration"
      ],
      "command": ["docker", "run", "-i", "--rm", "-v", "$HOME/.aws:/root/.aws:ro", "-e", "AWS_REGION=us-east-1", "-e", "AWS_PROFILE=default", "mcp/aws-api-mcp-server"],
      "context_tokens": 2000,
      "tags": ["aws", "cli", "cloud"],
      "added": "2024-12-01",
      "last_used": "2024-12-05",
      "use_count": 15,
      "notes": "Lighter weight than MCP_DOCKER for AWS-only work"
    }
  },
  "archived": {
    "old-postgres-mcp": {
      "status": "archived",
      "source": "docker",
      "description": "PostgreSQL database MCP - archived because we switched to Supabase",
      "capabilities": ["SQL queries", "Schema inspection", "Data export"],
      "command": ["docker", "run", "-i", "--rm", "mcp/postgres-server"],
      "context_tokens": 1500,
      "tags": ["database", "postgres", "sql"],
      "added": "2024-11-15",
      "archived": "2024-12-01",
      "archive_reason": "Switched to Supabase, no longer needed",
      "use_count": 8
    }
  },
  "config": {
    "default_profile": null,
    "auto_apply_on_cd": false,
    "sync_with_docker_catalog": true
  }
}
```

#### Server Description Requirements

Every server entry MUST include:

| Field | Required | Description |
|-------|----------|-------------|
| `status` | Yes | "active" or "archived" |
| `source` | Yes | "docker", "docker-gateway", "npx", "local", "remote" |
| `description` | Yes | 1-2 sentence human-readable description of what this MCP does |
| `capabilities` | Yes | Array of specific things this MCP can do (for intelligent selection) |
| `command` | Yes | Array of command parts to launch the MCP |
| `context_tokens` | Yes | Estimated context window usage when enabled |
| `tags` | Yes | Array of keywords for searching/filtering |
| `added` | Yes | Date this MCP was first added to registry |
| `last_used` | No | Date this MCP was last enabled |
| `use_count` | No | Number of times this MCP has been enabled |
| `notes` | No | User notes about when/why to use this MCP |

#### Docker MCP Integration

**All Docker MCPs are managed through this system.** When a user:
1. Enables a Docker MCP via `docker mcp catalog add` or `mcp-add`
2. The registry is automatically updated with the MCP details
3. Description and capabilities are fetched from the Docker catalog
4. The MCP is tracked for future use

**Sync with Docker Catalog:**
- On `/mcp-manage` discovery, fetch latest catalog via `docker mcp catalog show`
- Compare with registry to identify new/updated MCPs
- Offer to update descriptions for existing MCPs if catalog has newer info

#### Project Config (`.mcp-project.json`)

```json
{
  "project": "my-project",
  "description": "Project description",
  "profile": "aws-dev",
  "enabled": ["MCP_DOCKER", "aws-api"],
  "disabled": [],
  "notes": "Optional notes about this configuration"
}
```

## Features

### 1. Session Initialization (Automatic)

**Trigger:** Start of new Claude Code conversation (via `CLAUDE.md`)

**Behavior:**
1. Check if `.mcp-project.json` exists in project root
2. Run `claude mcp list` to get currently enabled MCPs
3. Compare project config expectations vs actual state
4. If mismatch, notify user: "This project expects MCPs: X, Y but currently enabled: A, B. Run `/mcp-manage` to configure."

**No action taken automatically** - user must explicitly run `/mcp-manage` to make changes.

### 2. `/mcp-manage` Command

Interactive MCP management command with the following capabilities:

#### 2.1 Status View
```
Current MCP Status:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ MCP_DOCKER (Docker Gateway)     ~20,000 tokens
✗ aws-api (AWS CLI)               ~2,000 tokens
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total context: ~20,000 tokens

Project config: .mcp-project.json found
Expected: MCP_DOCKER, aws-api
Status: MISMATCH - aws-api not enabled

What would you like to do?
```

#### 2.2 Enable/Disable MCPs
- Enable MCPs from the registry
- Disable currently running MCPs
- Show context token impact of changes

#### 2.3 Discovery
- Search Docker MCP catalog: `docker mcp catalog show`
- Use `mcp__MCP_DOCKER__mcp-find` for gateway-based search
- Show MCP descriptions and capabilities
- Add discovered MCPs to registry and optionally enable

#### 2.4 Profile Management
- List available profiles
- Apply a profile (enable all MCPs in profile, disable others)
- Create new profile from current enabled MCPs
- Set default profile for new projects

#### 2.5 Project Config Management
- Save current state to `.mcp-project.json`
- Load and apply `.mcp-project.json`
- Clear project config

#### 2.6 Archive Management
- **View archived MCPs** - Show all previously-used MCPs that are currently archived
- **Restore from archive** - Move an archived MCP back to active servers
- **Archive an MCP** - Move an active MCP to archive (with reason)
- **Permanently delete** - Remove from archive entirely (requires confirmation)

```
Archived MCPs:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  old-postgres-mcp    Archived: 2024-12-01
    Reason: Switched to Supabase, no longer needed
    Last used: 2024-11-28 (8 times total)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Actions: [R]estore  [D]elete permanently  [B]ack
```

### 3. MCP Sources

#### 3.1 Docker MCP Catalog (311+ servers available)
- Primary source for discovering new MCPs
- Search via `docker mcp catalog show` or `mcp-find` tool
- Automatically generate correct `docker run` commands
- **Auto-populate descriptions**: When adding from catalog, fetch full description and capabilities
- Categories include: databases, cloud providers, documentation, browser automation, AI tools, and more

#### 3.2 Custom Configurations
- User-defined MCPs in registry
- Support for non-Docker MCPs (npx, local binaries, etc.)
- Import from URLs or config files

#### 3.3 Remote Sources (Future)
- Community MCP registries
- Team-shared configurations
- GitHub-hosted MCP definitions

### 4. Intelligent MCP Selection

The rich descriptions and capabilities in the registry enable intelligent decision-making:

#### 4.1 Capability-Based Recommendations
When user describes what they need, match against capabilities:
```
User: "I need to work with AWS S3 and DynamoDB"

Recommended MCPs:
  ✓ MCP_DOCKER (already enabled)
    - AWS CLI execution with validation ← matches your needs

  ○ aws-api (available)
    - Execute any AWS CLI command ← matches your needs
    - Lighter weight if you only need AWS

  ○ amazon-dynamodb (from catalog)
    - Direct DynamoDB operations ← matches your needs
```

#### 4.2 Context Budget Planning
Show impact of MCP choices on context window:
```
Context Budget Planner:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current usage:     20,000 tokens (MCP_DOCKER)
If you add aws-api: +2,000 tokens → 22,000 total
Available context: ~178,000 tokens remaining
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 4.3 Usage-Based Suggestions
Suggest MCPs based on project files detected:
```
Project Analysis:
  Found: package.json, tsconfig.json, playwright.config.ts

Suggested MCPs:
  ✓ MCP_DOCKER - includes Context7 for npm/TS docs
  ○ playwright - you have Playwright tests (already in MCP_DOCKER)
```

### 5. Configuration Storage

All MCP configurations stored in `~/.config/claude-mcp/registry.json`:
- Server commands and arguments
- Environment variables (non-sensitive)
- Context token estimates
- Descriptions and tags
- Usage history and statistics

**Sensitive data:** API keys and secrets should be stored in:
- Environment variables
- macOS Keychain (future)
- AWS Secrets Manager (for team sharing)

## User Flows

### Flow 1: New Project Setup

1. User creates new project directory
2. User runs `/mcp-manage`
3. System shows available MCPs and profiles
4. User selects profile or individual MCPs
5. System enables selected MCPs
6. System offers to save as `.mcp-project.json`
7. User confirms, config saved to project

### Flow 2: Switching Projects

1. User opens existing project with `.mcp-project.json`
2. System (via CLAUDE.md) detects mismatch
3. System notifies: "Project expects X, Y but Z is enabled"
4. User runs `/mcp-manage`
5. System offers to apply project config
6. User confirms, MCPs reconfigured

### Flow 3: Discovering New MCPs

1. User runs `/mcp-manage`
2. User selects "Discover new MCPs"
3. System asks what capabilities needed
4. System searches Docker catalog
5. System shows matching MCPs with descriptions
6. User selects MCPs to add
7. System adds to registry and optionally enables

### Flow 4: Creating a Profile

1. User configures MCPs for specific workflow
2. User runs `/mcp-manage`
3. User selects "Create profile"
4. User provides profile name and description
5. System saves current MCPs as named profile
6. Profile available for future use

### Flow 5: Archiving an MCP

1. User runs `/mcp-manage`
2. User selects "Archive an MCP"
3. System shows active MCPs that can be archived
4. User selects MCP to archive
5. System prompts for archive reason (optional)
6. MCP moved to `archived` section with metadata preserved
7. MCP removed from active servers but available for restoration

### Flow 6: Restoring from Archive

1. User runs `/mcp-manage`
2. User selects "View archived MCPs"
3. System shows all archived MCPs with reasons and last-used dates
4. User selects MCP to restore
5. System moves MCP back to `servers` section
6. System offers to enable it immediately

## Technical Requirements

### Commands Used

| Command | Purpose |
|---------|---------|
| `claude mcp list` | Get currently enabled MCPs |
| `claude mcp add <name> <command...>` | Enable an MCP |
| `claude mcp remove <name>` | Disable an MCP |
| `docker mcp catalog show` | List available Docker MCPs |
| `mcp__MCP_DOCKER__mcp-find` | Search MCPs via gateway |

### File Operations

- Read/write JSON files (registry, project config)
- Environment variable expansion in commands (`$HOME`, etc.)
- File existence checks

### Error Handling

- MCP fails to start: Show error, suggest troubleshooting
- Docker not running: Detect and notify user
- Invalid config file: Report error location, offer to fix
- Permission issues: Suggest `chmod` commands

## Success Metrics

1. **Adoption:** Users create `.mcp-project.json` in >50% of projects
2. **Efficiency:** Average time to switch MCP configs <10 seconds
3. **Discovery:** Users add new MCPs from catalog at least monthly
4. **Profiles:** Users create at least 2 custom profiles

## Future Enhancements

1. **Team Sharing:** Sync profiles across team via git or cloud
2. **Auto-detection:** Suggest MCPs based on project files (package.json → node tools, etc.)
3. **Health Checks:** Periodic validation that enabled MCPs are responsive
4. **Cost Tracking:** Track actual token usage per MCP over time
5. **IDE Integration:** VS Code extension for visual MCP management

## Appendix: Current Implementation

### Existing Files

**`~/.claude/commands/mcp-manage.md`** - Current slash command that:
- Reads current MCP state
- Shows registry contents
- Offers enable/disable/discover/save/load options

**`~/.config/claude-mcp/registry.json`** - Current registry with:
- MCP_DOCKER (Docker Gateway)
- aws-api (AWS CLI)

**`~/.config/claude-mcp/mcp-helpers.sh`** - Shell helpers:
- `mcp-status` - Show enabled MCPs
- `mcp-apply` - Apply project config from terminal

**`CLAUDE.md`** - Session instructions including MCP check behavior
