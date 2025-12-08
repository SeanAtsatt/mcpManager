#!/bin/bash
# MCP Helpers - Source this in your .zshrc or .bashrc
# Usage: source ~/.config/claude-mcp/mcp-helpers.sh
#
# Commands:
#   mcp-status    - Show currently enabled MCPs and project config
#   mcp-apply     - Apply .mcp-project.json from current directory
#   mcp-list      - List all available MCPs from registry
#   mcp-profiles  - List available profiles
#   mcp-profile   - Apply a named profile
#   mcp-archive   - Archive an MCP (soft delete)
#   mcp-restore   - Restore an archived MCP
#   mcp-search    - Search for MCPs by keyword

set -o pipefail

# Colors
_MCP_GREEN='\033[0;32m'
_MCP_YELLOW='\033[1;33m'
_MCP_CYAN='\033[0;36m'
_MCP_RED='\033[0;31m'
_MCP_GRAY='\033[0;90m'
_MCP_NC='\033[0m'
_MCP_BOLD='\033[1m'

# Config paths
MCP_REGISTRY="$HOME/.config/claude-mcp/registry.json"
MCP_CONFIG_DIR="$HOME/.config/claude-mcp"

# Ensure config directory exists
_mcp_ensure_config() {
    if [ ! -d "$MCP_CONFIG_DIR" ]; then
        mkdir -p "$MCP_CONFIG_DIR"
    fi
    if [ ! -f "$MCP_REGISTRY" ]; then
        echo -e "${_MCP_RED}Registry not found. Run setup.sh first.${_MCP_NC}"
        return 1
    fi
}

# Show current MCP status
mcp-status() {
    _mcp_ensure_config || return 1

    echo -e "${_MCP_CYAN}${_MCP_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_MCP_NC}"
    echo -e "${_MCP_CYAN}${_MCP_BOLD}         MCP Status${_MCP_NC}"
    echo -e "${_MCP_CYAN}${_MCP_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_MCP_NC}"
    echo ""

    # Get enabled MCPs
    local enabled_mcps=$(claude mcp list 2>/dev/null | grep -v "Checking" | grep -v "^$" | grep ":" | cut -d: -f1)
    local total_tokens=0

    if [ -z "$enabled_mcps" ]; then
        echo -e "  ${_MCP_GRAY}No MCPs currently enabled${_MCP_NC}"
    else
        echo -e "${_MCP_BOLD}Enabled:${_MCP_NC}"
        while IFS= read -r mcp; do
            if [ -n "$mcp" ]; then
                local tokens=$(python3 -c "
import json
reg = json.load(open('$MCP_REGISTRY'))
server = reg.get('servers', {}).get('$mcp', {})
print(server.get('context_tokens', 0))
" 2>/dev/null || echo "0")
                total_tokens=$((total_tokens + tokens))
                printf "  ${_MCP_GREEN}✓${_MCP_NC} %-20s ${_MCP_GRAY}~%s tokens${_MCP_NC}\n" "$mcp" "$tokens"
            fi
        done <<< "$enabled_mcps"
    fi

    echo ""
    echo -e "${_MCP_BOLD}Total context:${_MCP_NC} ~$total_tokens tokens"
    echo ""

    # Check project config
    if [ -f ".mcp-project.json" ]; then
        local project=$(python3 -c "import json; print(json.load(open('.mcp-project.json')).get('project', 'unknown'))" 2>/dev/null)
        local expected=$(python3 -c "import json; print(' '.join(json.load(open('.mcp-project.json')).get('enabled', [])))" 2>/dev/null)
        echo -e "${_MCP_CYAN}Project:${_MCP_NC} $project"
        echo -e "${_MCP_CYAN}Expected:${_MCP_NC} $expected"

        # Check for mismatches
        local mismatch=false
        for exp in $expected; do
            if ! echo "$enabled_mcps" | grep -q "^$exp$"; then
                mismatch=true
                break
            fi
        done

        if [ "$mismatch" = true ]; then
            echo -e "${_MCP_YELLOW}Status: MISMATCH - run 'mcp-apply' to fix${_MCP_NC}"
        else
            echo -e "${_MCP_GREEN}Status: OK${_MCP_NC}"
        fi
    else
        echo -e "${_MCP_GRAY}No project config (.mcp-project.json)${_MCP_NC}"
    fi

    echo -e "${_MCP_CYAN}${_MCP_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_MCP_NC}"
}

# Apply project config
mcp-apply() {
    _mcp_ensure_config || return 1

    local config=".mcp-project.json"
    if [ ! -f "$config" ]; then
        echo -e "${_MCP_YELLOW}No .mcp-project.json in current directory${_MCP_NC}"
        return 1
    fi

    local project=$(python3 -c "import json; print(json.load(open('$config')).get('project', 'unknown'))" 2>/dev/null)
    local enabled=$(python3 -c "import json; print(' '.join(json.load(open('$config')).get('enabled', [])))" 2>/dev/null)
    local disabled=$(python3 -c "import json; print(' '.join(json.load(open('$config')).get('disabled', [])))" 2>/dev/null)

    echo -e "${_MCP_CYAN}${_MCP_BOLD}Applying MCP config for: $project${_MCP_NC}"
    echo ""

    # Disable first
    for name in $disabled; do
        if claude mcp list 2>/dev/null | grep -q "^$name:"; then
            claude mcp remove "$name" 2>/dev/null && \
                echo -e "  ${_MCP_YELLOW}✗ $name disabled${_MCP_NC}"
        fi
    done

    # Enable from registry
    for name in $enabled; do
        if claude mcp list 2>/dev/null | grep -q "^$name:"; then
            echo -e "  ${_MCP_GREEN}✓ $name already enabled${_MCP_NC}"
        else
            local cmd=$(python3 -c "
import json
import os
reg = json.load(open('$MCP_REGISTRY'))
server = reg.get('servers', {}).get('$name', {})
cmd = server.get('command', [])
cmd = [c.replace('\$HOME', os.environ['HOME']) for c in cmd]
print(' '.join(cmd))
" 2>/dev/null)
            if [ -n "$cmd" ] && [ "$cmd" != "" ]; then
                claude mcp add "$name" $cmd 2>/dev/null && \
                    echo -e "  ${_MCP_GREEN}✓ $name enabled${_MCP_NC}"
            else
                echo -e "  ${_MCP_RED}✗ $name not found in registry${_MCP_NC}"
            fi
        fi
    done

    echo ""
    mcp-status
}

# List available MCPs from registry
mcp-list() {
    _mcp_ensure_config || return 1

    echo -e "${_MCP_CYAN}${_MCP_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_MCP_NC}"
    echo -e "${_MCP_CYAN}${_MCP_BOLD}       Available MCPs${_MCP_NC}"
    echo -e "${_MCP_CYAN}${_MCP_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_MCP_NC}"
    echo ""

    python3 << 'PYTHON'
import json
import os

reg = json.load(open(os.environ['HOME'] + '/.config/claude-mcp/registry.json'))

# Active servers
print("\033[1mActive Servers:\033[0m")
for name, server in reg.get('servers', {}).items():
    if server.get('status') == 'active':
        desc = server.get('description', 'No description')[:55]
        tokens = server.get('context_tokens', '?')
        tags = ', '.join(server.get('tags', [])[:3])
        print(f"  \033[0;32m●\033[0m {name}")
        print(f"    {desc}...")
        print(f"    \033[0;90m~{tokens} tokens | {tags}\033[0m")
        print()

# Archived servers
archived = reg.get('archived', {})
if archived:
    print("\033[1mArchived:\033[0m")
    for name, server in archived.items():
        reason = server.get('archive_reason', 'No reason given')[:40]
        print(f"  \033[0;90m○ {name} - {reason}\033[0m")
    print()
PYTHON

    echo -e "${_MCP_CYAN}${_MCP_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_MCP_NC}"
}

# List available profiles
mcp-profiles() {
    _mcp_ensure_config || return 1

    echo -e "${_MCP_CYAN}${_MCP_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_MCP_NC}"
    echo -e "${_MCP_CYAN}${_MCP_BOLD}       Available Profiles${_MCP_NC}"
    echo -e "${_MCP_CYAN}${_MCP_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_MCP_NC}"
    echo ""

    python3 << 'PYTHON'
import json
import os

reg = json.load(open(os.environ['HOME'] + '/.config/claude-mcp/registry.json'))

for name, profile in reg.get('profiles', {}).items():
    desc = profile.get('description', 'No description')
    mcps = ', '.join(profile.get('mcps', []))
    last_used = profile.get('last_used', 'Never')
    print(f"  \033[1m{name}\033[0m")
    print(f"    {desc}")
    print(f"    \033[0;90mMCPs: {mcps}\033[0m")
    print(f"    \033[0;90mLast used: {last_used}\033[0m")
    print()
PYTHON

    echo -e "Use ${_MCP_CYAN}mcp-profile <name>${_MCP_NC} to apply a profile"
    echo -e "${_MCP_CYAN}${_MCP_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_MCP_NC}"
}

# Apply a named profile
mcp-profile() {
    _mcp_ensure_config || return 1

    local profile_name="$1"
    if [ -z "$profile_name" ]; then
        echo -e "${_MCP_YELLOW}Usage: mcp-profile <profile-name>${_MCP_NC}"
        echo ""
        mcp-profiles
        return 1
    fi

    local mcps=$(python3 -c "
import json
import os
reg = json.load(open(os.environ['HOME'] + '/.config/claude-mcp/registry.json'))
profile = reg.get('profiles', {}).get('$profile_name')
if profile:
    print(' '.join(profile.get('mcps', [])))
else:
    print('')
" 2>/dev/null)

    if [ -z "$mcps" ]; then
        echo -e "${_MCP_RED}Profile '$profile_name' not found${_MCP_NC}"
        return 1
    fi

    echo -e "${_MCP_CYAN}${_MCP_BOLD}Applying profile: $profile_name${_MCP_NC}"
    echo ""

    # Get currently enabled MCPs
    local current=$(claude mcp list 2>/dev/null | grep -v "Checking" | grep -v "^$" | grep ":" | cut -d: -f1)

    # Disable MCPs not in profile
    for mcp in $current; do
        if ! echo "$mcps" | grep -q "\b$mcp\b"; then
            claude mcp remove "$mcp" 2>/dev/null && \
                echo -e "  ${_MCP_YELLOW}✗ $mcp disabled${_MCP_NC}"
        fi
    done

    # Enable MCPs in profile
    for name in $mcps; do
        if claude mcp list 2>/dev/null | grep -q "^$name:"; then
            echo -e "  ${_MCP_GREEN}✓ $name already enabled${_MCP_NC}"
        else
            local cmd=$(python3 -c "
import json
import os
reg = json.load(open(os.environ['HOME'] + '/.config/claude-mcp/registry.json'))
server = reg.get('servers', {}).get('$name', {})
cmd = server.get('command', [])
cmd = [c.replace('\$HOME', os.environ['HOME']) for c in cmd]
print(' '.join(cmd))
" 2>/dev/null)
            if [ -n "$cmd" ] && [ "$cmd" != "" ]; then
                claude mcp add "$name" $cmd 2>/dev/null && \
                    echo -e "  ${_MCP_GREEN}✓ $name enabled${_MCP_NC}"
            fi
        fi
    done

    # Update last_used in registry
    python3 -c "
import json
import os
from datetime import datetime
reg_path = os.environ['HOME'] + '/.config/claude-mcp/registry.json'
reg = json.load(open(reg_path))
if '$profile_name' in reg.get('profiles', {}):
    reg['profiles']['$profile_name']['last_used'] = datetime.now().strftime('%Y-%m-%d')
    reg['last_updated'] = datetime.now().isoformat() + 'Z'
    json.dump(reg, open(reg_path, 'w'), indent=2)
" 2>/dev/null

    echo ""
    mcp-status
}

# Archive an MCP
mcp-archive() {
    _mcp_ensure_config || return 1

    local mcp_name="$1"
    local reason="$2"

    if [ -z "$mcp_name" ]; then
        echo -e "${_MCP_YELLOW}Usage: mcp-archive <mcp-name> [reason]${_MCP_NC}"
        return 1
    fi

    python3 << PYTHON
import json
import os
from datetime import datetime

reg_path = os.environ['HOME'] + '/.config/claude-mcp/registry.json'
reg = json.load(open(reg_path))

mcp_name = '$mcp_name'
reason = '$reason' or 'Archived by user'

if mcp_name not in reg.get('servers', {}):
    print(f"\033[0;31mMCP '{mcp_name}' not found in registry\033[0m")
    exit(1)

server = reg['servers'].pop(mcp_name)
server['status'] = 'archived'
server['archived'] = datetime.now().strftime('%Y-%m-%d')
server['archive_reason'] = reason

if 'archived' not in reg:
    reg['archived'] = {}
reg['archived'][mcp_name] = server
reg['last_updated'] = datetime.now().isoformat() + 'Z'

json.dump(reg, open(reg_path, 'w'), indent=2)
print(f"\033[0;32m✓ {mcp_name} archived\033[0m")
print(f"  Reason: {reason}")
PYTHON

    # Also disable if currently enabled
    if claude mcp list 2>/dev/null | grep -q "^$mcp_name:"; then
        claude mcp remove "$mcp_name" 2>/dev/null
        echo -e "  ${_MCP_YELLOW}Also disabled from current session${_MCP_NC}"
    fi
}

# Restore an archived MCP
mcp-restore() {
    _mcp_ensure_config || return 1

    local mcp_name="$1"

    if [ -z "$mcp_name" ]; then
        echo -e "${_MCP_YELLOW}Usage: mcp-restore <mcp-name>${_MCP_NC}"
        echo ""
        echo -e "${_MCP_BOLD}Archived MCPs:${_MCP_NC}"
        python3 -c "
import json
import os
reg = json.load(open(os.environ['HOME'] + '/.config/claude-mcp/registry.json'))
for name in reg.get('archived', {}).keys():
    print(f'  {name}')
" 2>/dev/null
        return 1
    fi

    python3 << PYTHON
import json
import os
from datetime import datetime

reg_path = os.environ['HOME'] + '/.config/claude-mcp/registry.json'
reg = json.load(open(reg_path))

mcp_name = '$mcp_name'

if mcp_name not in reg.get('archived', {}):
    print(f"\033[0;31mMCP '{mcp_name}' not found in archive\033[0m")
    exit(1)

server = reg['archived'].pop(mcp_name)
server['status'] = 'active'
if 'archived' in server:
    del server['archived']
if 'archive_reason' in server:
    del server['archive_reason']

reg['servers'][mcp_name] = server
reg['last_updated'] = datetime.now().isoformat() + 'Z'

json.dump(reg, open(reg_path, 'w'), indent=2)
print(f"\033[0;32m✓ {mcp_name} restored to active servers\033[0m")
PYTHON
}

# Search MCPs by keyword
mcp-search() {
    _mcp_ensure_config || return 1

    local query="$1"
    if [ -z "$query" ]; then
        echo -e "${_MCP_YELLOW}Usage: mcp-search <keyword>${_MCP_NC}"
        return 1
    fi

    echo -e "${_MCP_CYAN}${_MCP_BOLD}Searching for: $query${_MCP_NC}"
    echo ""

    python3 << PYTHON
import json
import os

query = '$query'.lower()
reg = json.load(open(os.environ['HOME'] + '/.config/claude-mcp/registry.json'))

found = False
for name, server in reg.get('servers', {}).items():
    desc = server.get('description', '').lower()
    tags = ' '.join(server.get('tags', [])).lower()
    caps = ' '.join(server.get('capabilities', [])).lower()

    if query in name.lower() or query in desc or query in tags or query in caps:
        found = True
        tokens = server.get('context_tokens', '?')
        print(f"  \033[0;32m●\033[0m \033[1m{name}\033[0m (~{tokens} tokens)")
        print(f"    {server.get('description', 'No description')[:60]}...")

        # Show matching capabilities
        matching_caps = [c for c in server.get('capabilities', []) if query in c.lower()]
        if matching_caps:
            print(f"    \033[0;90mMatching: {matching_caps[0]}\033[0m")
        print()

if not found:
    print(f"  No MCPs found matching '{query}'")
    print(f"  Try: mcp-find in Claude Code for Docker catalog search")
PYTHON
}

# Create a new profile from current config
mcp-profile-create() {
    _mcp_ensure_config || return 1

    local profile_name="$1"
    local description="$2"

    if [ -z "$profile_name" ]; then
        echo -e "${_MCP_YELLOW}Usage: mcp-profile-create <name> [description]${_MCP_NC}"
        return 1
    fi

    local current=$(claude mcp list 2>/dev/null | grep -v "Checking" | grep -v "^$" | grep ":" | cut -d: -f1 | tr '\n' ' ')

    if [ -z "$current" ]; then
        echo -e "${_MCP_RED}No MCPs currently enabled${_MCP_NC}"
        return 1
    fi

    python3 << PYTHON
import json
import os
from datetime import datetime

reg_path = os.environ['HOME'] + '/.config/claude-mcp/registry.json'
reg = json.load(open(reg_path))

profile_name = '$profile_name'
description = '$description' or f'Custom profile created on {datetime.now().strftime("%Y-%m-%d")}'
mcps = '$current'.strip().split()

if 'profiles' not in reg:
    reg['profiles'] = {}

reg['profiles'][profile_name] = {
    'description': description,
    'mcps': mcps,
    'created': datetime.now().strftime('%Y-%m-%d'),
    'last_used': None
}
reg['last_updated'] = datetime.now().isoformat() + 'Z'

json.dump(reg, open(reg_path, 'w'), indent=2)
print(f"\033[0;32m✓ Profile '{profile_name}' created\033[0m")
print(f"  MCPs: {', '.join(mcps)}")
PYTHON
}

# Save current state to project config
mcp-save() {
    _mcp_ensure_config || return 1

    local project_name="$1"
    if [ -z "$project_name" ]; then
        project_name=$(basename "$(pwd)")
    fi

    local enabled=$(claude mcp list 2>/dev/null | grep -v "Checking" | grep -v "^$" | grep ":" | cut -d: -f1 | tr '\n' ' ')

    if [ -z "$enabled" ]; then
        echo -e "${_MCP_YELLOW}No MCPs currently enabled${_MCP_NC}"
        return 1
    fi

    python3 << PYTHON
import json
from datetime import datetime

project_name = '$project_name'
enabled = '$enabled'.strip().split()

config = {
    'project': project_name,
    'description': f'MCP configuration for {project_name}',
    'enabled': enabled,
    'disabled': [],
    'notes': f'Created on {datetime.now().strftime("%Y-%m-%d")}'
}

json.dump(config, open('.mcp-project.json', 'w'), indent=2)
print(f"\033[0;32m✓ Saved to .mcp-project.json\033[0m")
print(f"  Project: {project_name}")
print(f"  Enabled: {', '.join(enabled)}")
PYTHON
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

echo -e "${_MCP_GREEN}MCP helpers loaded${_MCP_NC}"
echo -e "  ${_MCP_GRAY}mcp-status, mcp-apply, mcp-list, mcp-profiles, mcp-profile${_MCP_NC}"
echo -e "  ${_MCP_GRAY}mcp-archive, mcp-restore, mcp-search, mcp-save${_MCP_NC}"
