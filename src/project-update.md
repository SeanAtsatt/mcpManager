# Project Update

Run this command to apply pending updates and fixes to the current project's configuration.

## Overview

This command performs maintenance tasks that `/startup` detected but didn't automatically fix. It handles:

1. **MCP Config Migration** - Update `.mcp-project.json` to latest schema
2. **Permissions Cleanup** - Remove redundant local permission files
3. **Future updates** - Additional migrations will be added here

## Step 1: Check for Issues

Before making changes, scan for issues:

```python
import json
import os

issues = []

# Check 1: MCP config needs migration
if os.path.exists('.mcp-project.json'):
    with open('.mcp-project.json') as f:
        config = json.load(f)
    if 'servers' in config and 'docker_mcps' not in config:
        issues.append('mcp_schema_servers')
    if 'mcps' in config and 'docker_mcps' not in config:
        issues.append('mcp_schema_mcps')
    if 'schema_version' not in config:
        issues.append('mcp_schema_version')

# Check 2: Redundant local permissions file
if os.path.exists('.claude/settings.local.json'):
    issues.append('redundant_local_settings')

print(issues)
```

If no issues found, report "Project is up to date!" and exit.

## Step 2: Report and Confirm

Present the issues found:

```
Project Update
═══════════════════════════════════════════════════

Issues detected:
  • [mcp_schema_servers] .mcp-project.json uses old 'servers' field
  • [mcp_schema_version] .mcp-project.json missing schema_version
  • [redundant_local_settings] .claude/settings.local.json is redundant

Ready to fix these issues?
```

Use AskUserQuestion with options:
1. **Yes, fix all issues** - Apply all updates
2. **Show me what will change** - Preview changes before applying
3. **No, cancel** - Exit without changes

## Step 3: Apply Updates

### MCP Config Migration

If `mcp_schema_servers`, `mcp_schema_mcps`, or `mcp_schema_version` issues exist:

```python
import json

with open('.mcp-project.json') as f:
    config = json.load(f)

changes = []

# Migration 1: servers -> docker_mcps
if 'servers' in config and 'docker_mcps' not in config:
    config['docker_mcps'] = config.pop('servers')
    changes.append("Renamed 'servers' to 'docker_mcps'")

# Migration 2: mcps -> docker_mcps
if 'mcps' in config and 'docker_mcps' not in config:
    config['docker_mcps'] = config.pop('mcps')
    changes.append("Renamed 'mcps' to 'docker_mcps'")

# Migration 3: Add schema version
if 'schema_version' not in config:
    config['schema_version'] = '2.0'
    changes.append("Added schema_version: 2.0")

with open('.mcp-project.json', 'w') as f:
    json.dump(config, f, indent=2)

for change in changes:
    print(f"  ✓ {change}")
```

### Permissions Cleanup

If `redundant_local_settings` issue exists:

1. Read `.claude/settings.local.json`
2. Check if it only contains permissions (no other important config)
3. If safe to remove, delete the file:
   ```bash
   rm .claude/settings.local.json
   ```
4. Report: `✓ Removed redundant .claude/settings.local.json`

**Important:** Before deleting, verify that:
- The file only contains `permissions` key
- Global `~/.claude/settings.json` has permissions configured
- No project-specific overrides are needed

If unsure, ask the user before deleting.

## Step 4: Report Results

```
Project Update Complete
═══════════════════════════════════════════════════

Changes applied:
  ✓ Renamed 'servers' to 'docker_mcps' in .mcp-project.json
  ✓ Added schema_version: 2.0 to .mcp-project.json
  ✓ Removed redundant .claude/settings.local.json

Your project is now up to date!
```

## Future Updates

As new maintenance tasks are added, document them here:

| Version | Update | Description |
|---------|--------|-------------|
| 2.0 | MCP Schema | Migrate servers/mcps to docker_mcps |
| 2.0 | Permissions | Clean up redundant local settings |

## Notes

- This command is idempotent - safe to run multiple times
- Always shows what will change before applying
- Backs up files before destructive operations (if needed)
- Run `/startup` after to verify everything is working
