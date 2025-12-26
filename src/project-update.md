# Project Update

Run this command to migrate from old config format or fix project configuration issues.

## Overview

This command performs maintenance tasks that `/startup` detected but didn't automatically fix. It handles:

1. **Config Migration** - Migrate from `.mcp-project.json` to `.mcp.json` + `.docker-mcp.yaml`
2. **Permissions Cleanup** - Remove redundant local permission files
3. **Missing Config** - Initialize project config if missing

## Step 1: Check for Issues

Before making changes, scan for issues:

```python
import os
import json
import yaml

issues = []

# Check 1: Old .mcp-project.json exists (needs migration)
if os.path.exists('.mcp-project.json'):
    issues.append('migrate_old_config')

# Check 2: Missing .mcp.json
if not os.path.exists('.mcp.json'):
    issues.append('missing_mcp_json')

# Check 3: Missing .docker-mcp.yaml (but .mcp.json exists)
if os.path.exists('.mcp.json') and not os.path.exists('.docker-mcp.yaml'):
    issues.append('missing_docker_yaml')

# Check 4: Redundant local permissions file
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
  • [migrate_old_config] Old .mcp-project.json needs migration
  • [missing_mcp_json] Project missing .mcp.json
  • [redundant_local_settings] .claude/settings.local.json is redundant

Ready to fix these issues?
```

Use AskUserQuestion with options:
1. **Yes, fix all issues** - Apply all updates
2. **Show me what will change** - Preview changes before applying
3. **No, cancel** - Exit without changes

## Step 3: Apply Updates

### Migrate Old Config

If `migrate_old_config` issue exists:

```python
import json
import yaml

# Read old config
with open('.mcp-project.json') as f:
    old_config = json.load(f)

# Extract server list
servers = old_config.get('docker_mcps',
           old_config.get('servers',
           old_config.get('mcps', ['context7'])))

# Create .mcp.json
mcp_json = {
    "mcpServers": {
        "project-docker-gateway": {
            "command": "docker",
            "args": ["mcp", "gateway", "run", "--config", ".docker-mcp.yaml"]
        },
        "claude-in-chrome": {
            "enabled": True
        }
    }
}

with open('.mcp.json', 'w') as f:
    json.dump(mcp_json, f, indent=2)

# Create .docker-mcp.yaml
docker_yaml = {
    "servers": servers
}

with open('.docker-mcp.yaml', 'w') as f:
    yaml.dump(docker_yaml, f, default_flow_style=False)

# Backup and remove old config
import shutil
shutil.move('.mcp-project.json', '.mcp-project.json.bak')

print("  ✓ Migrated .mcp-project.json to .mcp.json + .docker-mcp.yaml")
print("  ✓ Old config backed up to .mcp-project.json.bak")
```

### Initialize Missing Config

If `missing_mcp_json` or `missing_docker_yaml` issues exist:

Offer to run `/mcp-manage > Initialize Project` instead, or create default configs:

```python
import json
import yaml

# Create default .mcp.json if missing
if not os.path.exists('.mcp.json'):
    mcp_json = {
        "mcpServers": {
            "project-docker-gateway": {
                "command": "docker",
                "args": ["mcp", "gateway", "run", "--config", ".docker-mcp.yaml"]
            },
            "claude-in-chrome": {
                "enabled": True
            }
        }
    }
    with open('.mcp.json', 'w') as f:
        json.dump(mcp_json, f, indent=2)
    print("  ✓ Created .mcp.json")

# Create default .docker-mcp.yaml if missing
if not os.path.exists('.docker-mcp.yaml'):
    docker_yaml = {"servers": ["context7"]}
    with open('.docker-mcp.yaml', 'w') as f:
        yaml.dump(docker_yaml, f, default_flow_style=False)
    print("  ✓ Created .docker-mcp.yaml with default servers")
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
  ✓ Migrated .mcp-project.json to .mcp.json + .docker-mcp.yaml
  ✓ Old config backed up to .mcp-project.json.bak
  ✓ Removed redundant .claude/settings.local.json

New config files:
  .mcp.json         - Claude Code MCPs
  .docker-mcp.yaml  - Docker gateway servers

Restart your Claude Code session to use the new configuration.
```

## Migration Reference

| Old Format | New Format |
|------------|------------|
| `.mcp-project.json` | `.mcp.json` + `.docker-mcp.yaml` |
| `docker_mcps: [...]` | `servers:` in `.docker-mcp.yaml` |
| `servers: [...]` | `servers:` in `.docker-mcp.yaml` |
| `mcps: [...]` | `servers:` in `.docker-mcp.yaml` |
| `port: 8811` | (removed - Claude Code manages transport) |

## Notes

- This command is idempotent - safe to run multiple times
- Always shows what will change before applying
- Backs up old config before migration
- Run `/startup` after to verify everything is working
