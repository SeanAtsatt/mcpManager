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
SRC_DIR="$PROJECT_DIR/src"

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
    cp "$SRC_DIR/registry.json" "$CONFIG_DIR/registry.json"
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
    if profile.get('created') is None:
        profile['created'] = today
for server in reg['servers'].values():
    if server.get('added') is None:
        server['added'] = today
with open('$CONFIG_DIR/registry.json', 'w') as f:
    json.dump(reg, f, indent=2)
"
    echo -e "  ${GREEN}✓ Registry installed${NC}"
fi

# Install shell helpers
echo -e "${CYAN}Installing shell helpers...${NC}"
cp "$SRC_DIR/mcp-helpers.sh" "$CONFIG_DIR/mcp-helpers.sh"
chmod +x "$CONFIG_DIR/mcp-helpers.sh"
echo -e "  ${GREEN}✓ Shell helpers installed${NC}"

# Install slash command
echo -e "${CYAN}Installing /mcp-manage command...${NC}"
cp "$SRC_DIR/mcp-manage.md" "$COMMANDS_DIR/mcp-manage.md"
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
echo -e "     ${CYAN}mcp-status${NC}   - Show enabled MCPs"
echo -e "     ${CYAN}mcp-apply${NC}    - Apply project config"
echo -e "     ${CYAN}mcp-list${NC}     - List available MCPs"
echo -e "     ${CYAN}mcp-profiles${NC} - List profiles"
echo -e "     ${CYAN}mcp-profile${NC}  - Apply a profile"
echo -e "     ${CYAN}mcp-search${NC}   - Search MCPs"
echo -e "     ${CYAN}mcp-save${NC}     - Save config to project"
echo ""
echo -e "  5. Or use the interactive CLI:"
echo -e "     ${CYAN}./scripts/run.sh${NC}"
