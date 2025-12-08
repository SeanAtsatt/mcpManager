#!/bin/bash
# MCP Manager Run Script
# Interactive CLI for MCP management operations

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CONFIG_DIR="$HOME/.config/claude-mcp"
REGISTRY="$CONFIG_DIR/registry.json"

# Check if installed
check_installed() {
    if [ ! -f "$REGISTRY" ]; then
        echo -e "${YELLOW}MCP Manager not installed.${NC}"
        echo -e "Run ${CYAN}./scripts/setup.sh${NC} first."
        exit 1
    fi
}

# Show main menu
show_menu() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}        MCP Manager CLI${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${BOLD}1)${NC} Show MCP status"
    echo -e "  ${BOLD}2)${NC} List available MCPs"
    echo -e "  ${BOLD}3)${NC} List profiles"
    echo -e "  ${BOLD}4)${NC} Apply profile"
    echo -e "  ${BOLD}5)${NC} Apply project config"
    echo -e "  ${BOLD}6)${NC} Save current config to project"
    echo -e "  ${BOLD}7)${NC} Search MCPs"
    echo -e "  ${BOLD}8)${NC} View archived MCPs"
    echo ""
    echo -e "  ${BOLD}i)${NC} Install/reinstall MCP Manager"
    echo -e "  ${BOLD}t)${NC} Run tests"
    echo -e "  ${BOLD}b)${NC} Run build validation"
    echo -e "  ${BOLD}q)${NC} Quit"
    echo ""
}

# Show MCP status
show_status() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}         Current MCP Status${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Get enabled MCPs from claude
    local enabled_mcps=$(claude mcp list 2>/dev/null | grep -v "Checking" | grep -v "^$" | grep ":" | cut -d: -f1)
    local total_tokens=0

    if [ -z "$enabled_mcps" ]; then
        echo -e "  ${GRAY}No MCPs currently enabled${NC}"
    else
        echo -e "${BOLD}Enabled:${NC}"
        while IFS= read -r mcp; do
            if [ -n "$mcp" ]; then
                local tokens=$(python3 -c "
import json
reg = json.load(open('$REGISTRY'))
server = reg.get('servers', {}).get('$mcp', {})
print(server.get('context_tokens', 0))
" 2>/dev/null || echo "0")
                total_tokens=$((total_tokens + tokens))
                printf "  ${GREEN}✓${NC} %-25s ${GRAY}~%s tokens${NC}\n" "$mcp" "$tokens"
            fi
        done <<< "$enabled_mcps"
    fi

    echo ""
    echo -e "${BOLD}Total context:${NC} ~$total_tokens tokens"
    echo ""

    # Check project config
    if [ -f ".mcp-project.json" ]; then
        local project=$(python3 -c "import json; print(json.load(open('.mcp-project.json')).get('project', 'unknown'))" 2>/dev/null)
        local expected=$(python3 -c "import json; print(', '.join(json.load(open('.mcp-project.json')).get('enabled', [])))" 2>/dev/null)
        echo -e "${CYAN}Project:${NC} $project"
        echo -e "${CYAN}Expected MCPs:${NC} $expected"
    else
        echo -e "${GRAY}No .mcp-project.json in current directory${NC}"
    fi

    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# List available MCPs
list_mcps() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}        Available MCPs${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    python3 << PYTHON
import json
reg = json.load(open('$REGISTRY'))

print("\033[1mActive Servers:\033[0m")
for name, server in reg.get('servers', {}).items():
    if server.get('status') == 'active':
        desc = server.get('description', 'No description')[:50]
        tokens = server.get('context_tokens', '?')
        tags = ', '.join(server.get('tags', [])[:3])
        print(f"  \033[0;32m●\033[0m {name}")
        print(f"    {desc}...")
        print(f"    \033[0;90m~{tokens} tokens | Tags: {tags}\033[0m")
        print()
PYTHON

    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# List profiles
list_profiles() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}        Available Profiles${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    python3 << PYTHON
import json
reg = json.load(open('$REGISTRY'))

for name, profile in reg.get('profiles', {}).items():
    desc = profile.get('description', 'No description')
    mcps = ', '.join(profile.get('mcps', []))
    last_used = profile.get('last_used') or 'Never'
    print(f"  \033[1m{name}\033[0m")
    print(f"    {desc}")
    print(f"    \033[0;90mMCPs: {mcps}\033[0m")
    print(f"    \033[0;90mLast used: {last_used}\033[0m")
    print()
PYTHON

    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Apply a profile
apply_profile() {
    list_profiles
    echo ""
    read -p "Enter profile name (or 'c' to cancel): " profile_name

    if [ "$profile_name" = "c" ]; then
        return
    fi

    # Check if profile exists
    local exists=$(python3 -c "
import json
reg = json.load(open('$REGISTRY'))
print('yes' if '$profile_name' in reg.get('profiles', {}) else 'no')
" 2>/dev/null)

    if [ "$exists" != "yes" ]; then
        echo -e "${RED}Profile '$profile_name' not found${NC}"
        return
    fi

    echo -e "${CYAN}Applying profile: $profile_name${NC}"

    # Get MCPs in profile
    local mcps=$(python3 -c "
import json
reg = json.load(open('$REGISTRY'))
print(' '.join(reg['profiles']['$profile_name']['mcps']))
" 2>/dev/null)

    # Enable each MCP
    for mcp in $mcps; do
        if claude mcp list 2>/dev/null | grep -q "^$mcp:"; then
            echo -e "  ${GREEN}✓${NC} $mcp already enabled"
        else
            local cmd=$(python3 -c "
import json
import os
reg = json.load(open('$REGISTRY'))
server = reg.get('servers', {}).get('$mcp', {})
cmd = server.get('command', [])
cmd = [c.replace('\$HOME', os.environ['HOME']) for c in cmd]
print(' '.join(cmd))
" 2>/dev/null)
            if [ -n "$cmd" ]; then
                claude mcp add "$mcp" $cmd 2>/dev/null && \
                    echo -e "  ${GREEN}✓${NC} $mcp enabled"
            fi
        fi
    done

    echo ""
    echo -e "${GREEN}Profile applied!${NC}"
}

# Apply project config
apply_project() {
    if [ ! -f ".mcp-project.json" ]; then
        echo -e "${YELLOW}No .mcp-project.json in current directory${NC}"
        return
    fi

    local project=$(python3 -c "import json; print(json.load(open('.mcp-project.json')).get('project', 'unknown'))" 2>/dev/null)
    local enabled=$(python3 -c "import json; print(' '.join(json.load(open('.mcp-project.json')).get('enabled', [])))" 2>/dev/null)

    echo -e "${CYAN}Applying config for: $project${NC}"
    echo -e "MCPs to enable: $enabled"
    echo ""

    for mcp in $enabled; do
        if claude mcp list 2>/dev/null | grep -q "^$mcp:"; then
            echo -e "  ${GREEN}✓${NC} $mcp already enabled"
        else
            local cmd=$(python3 -c "
import json
import os
reg = json.load(open('$REGISTRY'))
server = reg.get('servers', {}).get('$mcp', {})
cmd = server.get('command', [])
cmd = [c.replace('\$HOME', os.environ['HOME']) for c in cmd]
print(' '.join(cmd))
" 2>/dev/null)
            if [ -n "$cmd" ]; then
                claude mcp add "$mcp" $cmd 2>/dev/null && \
                    echo -e "  ${GREEN}✓${NC} $mcp enabled"
            fi
        fi
    done

    echo ""
    echo -e "${GREEN}Project config applied!${NC}"
}

# Save current config
save_config() {
    local enabled=$(claude mcp list 2>/dev/null | grep -v "Checking" | grep -v "^$" | grep ":" | cut -d: -f1 | tr '\n' ' ')

    if [ -z "$enabled" ]; then
        echo -e "${YELLOW}No MCPs currently enabled${NC}"
        return
    fi

    local default_name=$(basename "$(pwd)")
    read -p "Project name [$default_name]: " project_name
    project_name=${project_name:-$default_name}

    python3 << PYTHON
import json
from datetime import datetime

enabled = '$enabled'.strip().split()

config = {
    'project': '$project_name',
    'description': 'MCP configuration for $project_name',
    'enabled': enabled,
    'disabled': [],
    'notes': f'Created on {datetime.now().strftime("%Y-%m-%d")}'
}

json.dump(config, open('.mcp-project.json', 'w'), indent=2)
print(f"\033[0;32m✓ Saved to .mcp-project.json\033[0m")
print(f"  Enabled: {', '.join(enabled)}")
PYTHON
}

# Search MCPs
search_mcps() {
    read -p "Search term: " query

    if [ -z "$query" ]; then
        return
    fi

    echo ""
    echo -e "${CYAN}Searching for: $query${NC}"
    echo ""

    python3 << PYTHON
import json
query = '$query'.lower()
reg = json.load(open('$REGISTRY'))

found = False
for name, server in reg.get('servers', {}).items():
    desc = server.get('description', '').lower()
    tags = ' '.join(server.get('tags', [])).lower()
    caps = ' '.join(server.get('capabilities', [])).lower()

    if query in name.lower() or query in desc or query in tags or query in caps:
        found = True
        tokens = server.get('context_tokens', '?')
        print(f"  \033[0;32m●\033[0m \033[1m{name}\033[0m (~{tokens} tokens)")
        print(f"    {server.get('description', 'No description')[:55]}...")
        print()

if not found:
    print(f"  No MCPs found matching '{query}'")
PYTHON
}

# View archived
view_archived() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}        Archived MCPs${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    python3 << PYTHON
import json
reg = json.load(open('$REGISTRY'))

archived = reg.get('archived', {})
if not archived:
    print("  \033[0;90mNo archived MCPs\033[0m")
else:
    for name, server in archived.items():
        reason = server.get('archive_reason', 'No reason given')
        archived_date = server.get('archived', 'Unknown')
        print(f"  \033[0;90m○\033[0m {name}")
        print(f"    Archived: {archived_date}")
        print(f"    Reason: {reason}")
        print()
PYTHON

    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Main loop
main() {
    check_installed

    while true; do
        show_menu
        read -p "Select option: " choice

        case $choice in
            1) show_status ;;
            2) list_mcps ;;
            3) list_profiles ;;
            4) apply_profile ;;
            5) apply_project ;;
            6) save_config ;;
            7) search_mcps ;;
            8) view_archived ;;
            i) "$PROJECT_DIR/scripts/setup.sh" ;;
            t) "$PROJECT_DIR/scripts/test.sh" ;;
            b) "$PROJECT_DIR/scripts/build.sh" ;;
            q|Q) echo "Goodbye!"; exit 0 ;;
            *) echo -e "${YELLOW}Invalid option${NC}" ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run
main
