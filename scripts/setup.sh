#!/bin/bash
# MCP Manager Setup Script
# Installs global registry, shell helpers, and slash command

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CONFIG_DIR="$HOME/.config/claude-mcp"
COMMANDS_DIR="$HOME/.claude/commands"

echo -e "${CYAN}${BOLD}MCP Manager Setup${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create directories
echo -e "${CYAN}Creating directories...${NC}"
mkdir -p "$CONFIG_DIR"
mkdir -p "$COMMANDS_DIR"

# Install registry (only if it doesn't exist or user confirms)
if [ -f "$CONFIG_DIR/registry.json" ]; then
    echo -e "${YELLOW}Registry already exists at $CONFIG_DIR/registry.json${NC}"
    read -p "Overwrite with default? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_REGISTRY=true
    else
        INSTALL_REGISTRY=false
    fi
else
    INSTALL_REGISTRY=true
fi

if [ "$INSTALL_REGISTRY" = true ]; then
    echo -e "${CYAN}Installing global registry...${NC}"
    cat > "$CONFIG_DIR/registry.json" << 'EOF'
{
  "version": "1.0",
  "last_updated": null,
  "profiles": {
    "minimal": {
      "description": "Just the Docker Gateway for docs lookup",
      "mcps": ["MCP_DOCKER"],
      "created": null,
      "last_used": null
    },
    "aws-dev": {
      "description": "AWS development with full tooling",
      "mcps": ["MCP_DOCKER", "aws-api"],
      "created": null,
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
      "added": null,
      "last_used": null,
      "use_count": 0,
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
      "added": null,
      "last_used": null,
      "use_count": 0,
      "notes": "Lighter weight than MCP_DOCKER for AWS-only work"
    }
  },
  "archived": {},
  "config": {
    "default_profile": null,
    "auto_apply_on_cd": false,
    "sync_with_docker_catalog": true
  }
}
EOF
    # Set timestamps
    python3 -c "
import json
from datetime import datetime
now = datetime.now().isoformat() + 'Z'
today = datetime.now().strftime('%Y-%m-%d')
with open('$CONFIG_DIR/registry.json', 'r') as f:
    reg = json.load(f)
reg['last_updated'] = now
for profile in reg['profiles'].values():
    profile['created'] = today
for server in reg['servers'].values():
    server['added'] = today
with open('$CONFIG_DIR/registry.json', 'w') as f:
    json.dump(reg, f, indent=2)
"
    echo -e "  ${GREEN}✓ Registry installed${NC}"
fi

# Install shell helpers
echo -e "${CYAN}Installing shell helpers...${NC}"
cat > "$CONFIG_DIR/mcp-helpers.sh" << 'EOF'
#!/bin/bash
# MCP Helpers - Source this in your .zshrc or .bashrc
# Usage: source ~/.config/claude-mcp/mcp-helpers.sh

_MCP_GREEN='\033[0;32m'
_MCP_YELLOW='\033[1;33m'
_MCP_CYAN='\033[0;36m'
_MCP_RED='\033[0;31m'
_MCP_NC='\033[0m'
_MCP_BOLD='\033[1m'

REGISTRY="$HOME/.config/claude-mcp/registry.json"

# Show current MCP status
mcp-status() {
    echo -e "${_MCP_CYAN}${_MCP_BOLD}Enabled MCPs:${_MCP_NC}"
    claude mcp list 2>/dev/null | grep -v "Checking" | grep -v "^$" || echo "  (none)"

    if [ -f ".mcp-project.json" ]; then
        echo ""
        local project=$(python3 -c "import json; print(json.load(open('.mcp-project.json')).get('project', 'unknown'))" 2>/dev/null)
        echo -e "${_MCP_CYAN}Project config: ${_MCP_BOLD}$project${_MCP_NC}"
    fi
}

# Apply project config
mcp-apply() {
    local config=".mcp-project.json"
    if [ ! -f "$config" ]; then
        echo -e "${_MCP_YELLOW}No .mcp-project.json in current directory${_MCP_NC}"
        return 1
    fi

    local project=$(python3 -c "import json; print(json.load(open('$config')).get('project', 'unknown'))" 2>/dev/null)
    local enabled=$(python3 -c "import json; print(' '.join(json.load(open('$config')).get('enabled', [])))" 2>/dev/null)
    local disabled=$(python3 -c "import json; print(' '.join(json.load(open('$config')).get('disabled', [])))" 2>/dev/null)

    echo -e "${_MCP_CYAN}Applying MCP config for: ${_MCP_BOLD}$project${_MCP_NC}"
    echo -e "  Enable: $enabled"
    echo -e "  Disable: $disabled"
    echo ""

    # Disable first
    for name in $disabled; do
        if claude mcp list 2>/dev/null | grep -q "^$name:"; then
            claude mcp remove "$name" 2>/dev/null && \
                echo -e "  ${_MCP_YELLOW}$name disabled${_MCP_NC}"
        fi
    done

    # Enable from registry
    for name in $enabled; do
        if claude mcp list 2>/dev/null | grep -q "^$name:"; then
            echo -e "  ${_MCP_GREEN}$name already enabled${_MCP_NC}"
        else
            local cmd=$(python3 -c "
import json
import os
reg = json.load(open('$REGISTRY'))
server = reg.get('servers', {}).get('$name', {})
cmd = server.get('command', [])
cmd = [c.replace('\$HOME', os.environ['HOME']) for c in cmd]
print(' '.join(cmd))
" 2>/dev/null)
            if [ -n "$cmd" ]; then
                claude mcp add "$name" $cmd 2>/dev/null && \
                    echo -e "  ${_MCP_GREEN}$name enabled${_MCP_NC}"
            else
                echo -e "  ${_MCP_RED}$name not found in registry${_MCP_NC}"
            fi
        fi
    done

    echo ""
    mcp-status
}

# List available MCPs from registry
mcp-list() {
    if [ ! -f "$REGISTRY" ]; then
        echo -e "${_MCP_RED}Registry not found at $REGISTRY${_MCP_NC}"
        return 1
    fi

    echo -e "${_MCP_CYAN}${_MCP_BOLD}Available MCPs:${_MCP_NC}"
    python3 -c "
import json
reg = json.load(open('$REGISTRY'))
for name, server in reg.get('servers', {}).items():
    status = server.get('status', 'unknown')
    desc = server.get('description', 'No description')[:60]
    tokens = server.get('context_tokens', '?')
    print(f'  {name}')
    print(f'    {desc}...')
    print(f'    ~{tokens} tokens')
    print()
"
}

# Check project config on cd (optional hook)
_mcp_cd_hook() {
    if [ -f ".mcp-project.json" ]; then
        local project=$(python3 -c "import json; print(json.load(open('.mcp-project.json')).get('project', ''))" 2>/dev/null)
        echo -e "${_MCP_CYAN}MCP config found for '$project' - run 'mcp-apply' to configure${_MCP_NC}"
    fi
}

# For zsh: uncomment to enable auto-prompt on cd
# autoload -U add-zsh-hook
# add-zsh-hook chpwd _mcp_cd_hook

echo -e "${_MCP_GREEN}MCP helpers loaded: mcp-status, mcp-apply, mcp-list${_MCP_NC}"
EOF
chmod +x "$CONFIG_DIR/mcp-helpers.sh"
echo -e "  ${GREEN}✓ Shell helpers installed${NC}"

# Install slash command
echo -e "${CYAN}Installing /mcp-manage command...${NC}"
cat > "$COMMANDS_DIR/mcp-manage.md" << 'EOF'
# MCP Management

You are helping the user manage their MCP (Model Context Protocol) servers.

## Context Files
- Registry: `~/.config/claude-mcp/registry.json` - Master list of all known MCPs
- Project config: `.mcp-project.json` in current directory (if exists)

## Your Tasks

1. **Read the current state**:
   - Run `claude mcp list` to see currently enabled MCPs
   - Read `~/.config/claude-mcp/registry.json` for the user's known servers
   - Check if `.mcp-project.json` exists in the current directory

2. **Present a status summary**:
   ```
   Current MCP Status:
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✓ MCP_DOCKER (Docker Gateway)     ~20,000 tokens
   ✗ aws-api (AWS CLI)               ~2,000 tokens
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Total context: ~20,000 tokens
   ```

3. **Ask what they want to do**:
   a) Enable/disable specific MCPs
   b) Discover new MCPs from Docker catalog
   c) Save current config to this project
   d) Load config from this project
   e) Manage profiles
   f) View/restore archived MCPs

4. **For discovery**:
   - Ask what capabilities the project needs (web scraping, AWS, database, etc.)
   - Search Docker catalog using `mcp__MCP_DOCKER__mcp-find` tool
   - Show matching MCPs with descriptions and context token estimates
   - Offer to add them to the registry and enable them

5. **For enabling/disabling**:
   - Use `claude mcp add <name> <command...>` to enable
   - Use `claude mcp remove <name>` to disable
   - Update the registry if adding new servers
   - Show context token impact of changes

6. **For project configs**:
   - Save: Write current enabled MCPs to `.mcp-project.json`
   - Load: Read `.mcp-project.json` and apply those settings

7. **For profiles**:
   - List available profiles from registry
   - Apply a profile (enable all MCPs in profile)
   - Create new profile from current enabled MCPs

## Important
- Always show context token estimates so user understands the cost
- Be conversational - this is an interactive management session
- After changes, show the new state with `claude mcp list`
- Never enable MCPs without user confirmation
EOF
echo -e "  ${GREEN}✓ Slash command installed${NC}"

echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Add to your shell config (~/.zshrc or ~/.bashrc):"
echo -e "     ${CYAN}source ~/.config/claude-mcp/mcp-helpers.sh${NC}"
echo ""
echo -e "  2. Reload your shell or run:"
echo -e "     ${CYAN}source ~/.config/claude-mcp/mcp-helpers.sh${NC}"
echo ""
echo -e "  3. In Claude Code, use ${CYAN}/mcp-manage${NC} to manage MCPs"
echo ""
echo -e "  4. From terminal, use:"
echo -e "     ${CYAN}mcp-status${NC}  - Show enabled MCPs"
echo -e "     ${CYAN}mcp-apply${NC}   - Apply project config"
echo -e "     ${CYAN}mcp-list${NC}    - List available MCPs"
