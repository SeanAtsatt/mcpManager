#!/bin/bash
# MCP Manager Build Script
# Validates all source files and prepares for installation

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

echo -e "${CYAN}${BOLD}MCP Manager Build${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Track errors
ERRORS=0

# Check required files exist
echo -e "${CYAN}Checking source files...${NC}"

check_file() {
    local file="$1"
    local desc="$2"
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $desc"
    else
        echo -e "  ${RED}✗${NC} $desc - NOT FOUND"
        ERRORS=$((ERRORS + 1))
    fi
}

check_file "$SRC_DIR/registry.json" "Registry template"
check_file "$SRC_DIR/mcp-helpers.sh" "Shell helpers"
check_file "$SRC_DIR/mcp-manage.md" "Slash command"
check_file "$PROJECT_DIR/README.md" "README"
check_file "$PROJECT_DIR/docs/PRD.md" "PRD documentation"

echo ""

# Validate JSON
echo -e "${CYAN}Validating JSON files...${NC}"

validate_json() {
    local file="$1"
    local name="$2"
    if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $name is valid JSON"
    else
        echo -e "  ${RED}✗${NC} $name has invalid JSON"
        ERRORS=$((ERRORS + 1))
    fi
}

validate_json "$SRC_DIR/registry.json" "Registry"

# Check for .mcp-project.json if it exists
if [ -f "$PROJECT_DIR/.mcp-project.json" ]; then
    validate_json "$PROJECT_DIR/.mcp-project.json" "Project config"
fi

echo ""

# Validate shell script syntax
echo -e "${CYAN}Validating shell scripts...${NC}"

validate_shell() {
    local file="$1"
    local name="$2"
    if bash -n "$file" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $name has valid syntax"
    else
        echo -e "  ${RED}✗${NC} $name has syntax errors"
        ERRORS=$((ERRORS + 1))
    fi
}

validate_shell "$SRC_DIR/mcp-helpers.sh" "Shell helpers"
validate_shell "$PROJECT_DIR/scripts/setup.sh" "Setup script"

echo ""

# Validate registry schema
echo -e "${CYAN}Validating registry schema...${NC}"

python3 << 'PYTHON'
import json
import sys

try:
    with open('src/registry.json') as f:
        reg = json.load(f)

    errors = []

    # Check required top-level keys
    required_keys = ['version', 'profiles', 'servers', 'config']
    for key in required_keys:
        if key not in reg:
            errors.append(f"Missing required key: {key}")

    # Validate servers
    for name, server in reg.get('servers', {}).items():
        required_server_keys = ['status', 'source', 'description', 'capabilities', 'command', 'context_tokens', 'tags']
        for key in required_server_keys:
            if key not in server:
                errors.append(f"Server '{name}' missing required key: {key}")

        if not isinstance(server.get('capabilities', []), list):
            errors.append(f"Server '{name}' capabilities must be a list")

        if not isinstance(server.get('command', []), list):
            errors.append(f"Server '{name}' command must be a list")

        if not isinstance(server.get('tags', []), list):
            errors.append(f"Server '{name}' tags must be a list")

    # Validate profiles
    for name, profile in reg.get('profiles', {}).items():
        required_profile_keys = ['description', 'mcps']
        for key in required_profile_keys:
            if key not in profile:
                errors.append(f"Profile '{name}' missing required key: {key}")

        # Check that profile MCPs exist in servers
        for mcp in profile.get('mcps', []):
            if mcp not in reg.get('servers', {}):
                errors.append(f"Profile '{name}' references unknown MCP: {mcp}")

    if errors:
        print("\033[0;31m  ✗ Registry schema errors:\033[0m")
        for err in errors:
            print(f"    - {err}")
        sys.exit(1)
    else:
        print("\033[0;32m  ✓ Registry schema is valid\033[0m")

except Exception as e:
    print(f"\033[0;31m  ✗ Registry validation failed: {e}\033[0m")
    sys.exit(1)
PYTHON

if [ $? -ne 0 ]; then
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Check Python availability (required for helpers)
echo -e "${CYAN}Checking dependencies...${NC}"

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo -e "  ${GREEN}✓${NC} Python3 available ($PYTHON_VERSION)"
else
    echo -e "  ${RED}✗${NC} Python3 not found (required for helpers)"
    ERRORS=$((ERRORS + 1))
fi

if command -v claude &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Claude CLI available"
else
    echo -e "  ${YELLOW}!${NC} Claude CLI not found (required for MCP management)"
fi

if command -v docker &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Docker available"
else
    echo -e "  ${YELLOW}!${NC} Docker not found (required for Docker MCPs)"
fi

echo ""

# Summary
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}Build successful!${NC}"
    echo ""
    echo -e "Next steps:"
    echo -e "  ${CYAN}./scripts/setup.sh${NC}  - Install to system"
    echo -e "  ${CYAN}./scripts/test.sh${NC}   - Run tests"
    exit 0
else
    echo -e "${RED}${BOLD}Build failed with $ERRORS error(s)${NC}"
    exit 1
fi
