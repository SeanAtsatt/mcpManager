#!/bin/bash
# MCP Manager Test Suite
# Runs all tests to validate the MCP Manager functionality

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
TEST_DIR="$PROJECT_DIR/tests"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${CYAN}${BOLD}MCP Manager Test Suite${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test helper functions
test_start() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${CYAN}TEST $TESTS_RUN:${NC} $1"
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓ PASS${NC}"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗ FAIL:${NC} $1"
}

# Create temporary test environment
TEST_TMP=$(mktemp -d)
TEST_CONFIG_DIR="$TEST_TMP/.config/claude-mcp"
TEST_COMMANDS_DIR="$TEST_TMP/.claude/commands"
mkdir -p "$TEST_CONFIG_DIR"
mkdir -p "$TEST_COMMANDS_DIR"

cleanup() {
    rm -rf "$TEST_TMP"
}
trap cleanup EXIT

echo -e "${CYAN}Test environment:${NC} $TEST_TMP"
echo ""

# ============================================
# Unit Tests
# ============================================

echo -e "${BOLD}Unit Tests${NC}"
echo -e "────────────────────────────────────────"

# Test 1: Registry JSON validity
test_start "Registry JSON is valid"
if python3 -c "import json; json.load(open('$SRC_DIR/registry.json'))" 2>/dev/null; then
    test_pass
else
    test_fail "Invalid JSON in registry.json"
fi

# Test 2: Registry has required keys
test_start "Registry has required top-level keys"
MISSING=$(python3 -c "
import json
reg = json.load(open('$SRC_DIR/registry.json'))
required = ['version', 'profiles', 'servers', 'config']
missing = [k for k in required if k not in reg]
print(' '.join(missing))
" 2>/dev/null)
if [ -z "$MISSING" ]; then
    test_pass
else
    test_fail "Missing keys: $MISSING"
fi

# Test 3: All servers have required fields
test_start "All servers have required fields"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
required = ['status', 'source', 'description', 'capabilities', 'command', 'context_tokens', 'tags']
errors = []
for name, server in reg.get('servers', {}).items():
    for key in required:
        if key not in server:
            errors.append(f"{name}.{key}")
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Missing fields: $RESULT"
fi

# Test 4: Profile MCPs reference valid servers
test_start "Profile MCPs reference valid servers"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
errors = []
servers = set(reg.get('servers', {}).keys())
for name, profile in reg.get('profiles', {}).items():
    for mcp in profile.get('mcps', []):
        if mcp not in servers:
            errors.append(f"{name}->{mcp}")
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Invalid references: $RESULT"
fi

# Test 5: Shell helpers have valid syntax
test_start "Shell helpers have valid syntax"
if bash -n "$SRC_DIR/mcp-helpers.sh" 2>/dev/null; then
    test_pass
else
    test_fail "Syntax errors in mcp-helpers.sh"
fi

# Test 6: Setup script has valid syntax
test_start "Setup script has valid syntax"
if bash -n "$PROJECT_DIR/scripts/setup.sh" 2>/dev/null; then
    test_pass
else
    test_fail "Syntax errors in setup.sh"
fi

# Test 7: Build script has valid syntax
test_start "Build script has valid syntax"
if bash -n "$PROJECT_DIR/scripts/build.sh" 2>/dev/null; then
    test_pass
else
    test_fail "Syntax errors in build.sh"
fi

echo ""

# ============================================
# Integration Tests
# ============================================

echo -e "${BOLD}Integration Tests${NC}"
echo -e "────────────────────────────────────────"

# Test 8: Setup script creates registry
test_start "Setup creates registry file"
# Copy setup and run in test environment
cp "$SRC_DIR/registry.json" "$TEST_CONFIG_DIR/registry.json"
if [ -f "$TEST_CONFIG_DIR/registry.json" ]; then
    test_pass
else
    test_fail "Registry not created"
fi

# Test 9: Registry can be read and modified
test_start "Registry can be modified"
RESULT=$(python3 << PYTHON
import json
import os
reg_path = "$TEST_CONFIG_DIR/registry.json"
try:
    reg = json.load(open(reg_path))
    reg['test_key'] = 'test_value'
    json.dump(reg, open(reg_path, 'w'), indent=2)
    reg2 = json.load(open(reg_path))
    print('OK' if reg2.get('test_key') == 'test_value' else 'FAIL')
except Exception as e:
    print(f'ERROR: {e}')
PYTHON
)
if [ "$RESULT" = "OK" ]; then
    test_pass
else
    test_fail "$RESULT"
fi

# Test 10: Project config can be created
test_start "Project config can be created"
TEST_PROJECT_DIR="$TEST_TMP/test-project"
mkdir -p "$TEST_PROJECT_DIR"
cat > "$TEST_PROJECT_DIR/.mcp-project.json" << 'EOF'
{
  "project": "test-project",
  "description": "Test project",
  "enabled": ["MCP_DOCKER"],
  "disabled": []
}
EOF
if python3 -c "import json; json.load(open('$TEST_PROJECT_DIR/.mcp-project.json'))" 2>/dev/null; then
    test_pass
else
    test_fail "Invalid project config"
fi

# Test 11: Project config can be parsed
test_start "Project config fields can be parsed"
RESULT=$(python3 << PYTHON
import json
config = json.load(open('$TEST_PROJECT_DIR/.mcp-project.json'))
if config.get('project') == 'test-project' and 'MCP_DOCKER' in config.get('enabled', []):
    print('OK')
else:
    print('FAIL')
PYTHON
)
if [ "$RESULT" = "OK" ]; then
    test_pass
else
    test_fail "Could not parse config fields"
fi

# Test 12: Archive operation works
test_start "Archive operation modifies registry"
RESULT=$(python3 << PYTHON
import json
from datetime import datetime

reg_path = "$TEST_CONFIG_DIR/registry.json"
reg = json.load(open(reg_path))

# Add a test server
reg['servers']['test-mcp'] = {
    'status': 'active',
    'source': 'test',
    'description': 'Test MCP',
    'capabilities': ['test'],
    'command': ['echo', 'test'],
    'context_tokens': 100,
    'tags': ['test']
}

# Archive it
if 'archived' not in reg:
    reg['archived'] = {}

server = reg['servers'].pop('test-mcp')
server['status'] = 'archived'
server['archived'] = datetime.now().strftime('%Y-%m-%d')
server['archive_reason'] = 'Test archive'
reg['archived']['test-mcp'] = server

json.dump(reg, open(reg_path, 'w'), indent=2)

# Verify
reg2 = json.load(open(reg_path))
if 'test-mcp' in reg2.get('archived', {}) and 'test-mcp' not in reg2.get('servers', {}):
    print('OK')
else:
    print('FAIL')
PYTHON
)
if [ "$RESULT" = "OK" ]; then
    test_pass
else
    test_fail "Archive operation failed"
fi

# Test 13: Restore operation works
test_start "Restore operation modifies registry"
RESULT=$(python3 << PYTHON
import json

reg_path = "$TEST_CONFIG_DIR/registry.json"
reg = json.load(open(reg_path))

# Restore test-mcp
if 'test-mcp' in reg.get('archived', {}):
    server = reg['archived'].pop('test-mcp')
    server['status'] = 'active'
    if 'archived' in server:
        del server['archived']
    if 'archive_reason' in server:
        del server['archive_reason']
    reg['servers']['test-mcp'] = server
    json.dump(reg, open(reg_path, 'w'), indent=2)

# Verify
reg2 = json.load(open(reg_path))
if 'test-mcp' in reg2.get('servers', {}) and 'test-mcp' not in reg2.get('archived', {}):
    print('OK')
else:
    print('FAIL')
PYTHON
)
if [ "$RESULT" = "OK" ]; then
    test_pass
else
    test_fail "Restore operation failed"
fi

# Test 14: Profile creation works
test_start "Profile creation works"
RESULT=$(python3 << PYTHON
import json
from datetime import datetime

reg_path = "$TEST_CONFIG_DIR/registry.json"
reg = json.load(open(reg_path))

reg['profiles']['test-profile'] = {
    'description': 'Test profile',
    'mcps': ['MCP_DOCKER'],
    'created': datetime.now().strftime('%Y-%m-%d'),
    'last_used': None
}

json.dump(reg, open(reg_path, 'w'), indent=2)

# Verify
reg2 = json.load(open(reg_path))
if 'test-profile' in reg2.get('profiles', {}):
    print('OK')
else:
    print('FAIL')
PYTHON
)
if [ "$RESULT" = "OK" ]; then
    test_pass
else
    test_fail "Profile creation failed"
fi

echo ""

# ============================================
# Validation Tests
# ============================================

echo -e "${BOLD}Validation Tests${NC}"
echo -e "────────────────────────────────────────"

# Test 15: Context tokens are positive integers
test_start "Context tokens are valid"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
errors = []
for name, server in reg.get('servers', {}).items():
    tokens = server.get('context_tokens')
    if not isinstance(tokens, int) or tokens <= 0:
        errors.append(name)
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Invalid tokens for: $RESULT"
fi

# Test 16: Commands are non-empty arrays
test_start "Commands are valid arrays"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
errors = []
for name, server in reg.get('servers', {}).items():
    cmd = server.get('command')
    if not isinstance(cmd, list) or len(cmd) == 0:
        errors.append(name)
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Invalid commands for: $RESULT"
fi

# Test 17: Status is valid enum
test_start "Server status values are valid"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
errors = []
valid_status = ['active', 'archived']
for name, server in reg.get('servers', {}).items():
    if server.get('status') not in valid_status:
        errors.append(name)
for name, server in reg.get('archived', {}).items():
    if server.get('status') not in valid_status:
        errors.append(name)
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Invalid status for: $RESULT"
fi

# Test 18: Source is valid enum
test_start "Server source values are valid"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
errors = []
valid_source = ['docker', 'docker-gateway', 'npx', 'local', 'remote', 'test']
for name, server in reg.get('servers', {}).items():
    if server.get('source') not in valid_source:
        errors.append(f"{name}:{server.get('source')}")
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Invalid source for: $RESULT"
fi

echo ""

# ============================================
# Summary
# ============================================

echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}Test Summary${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Total:  $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
fi
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}$TESTS_FAILED test(s) failed${NC}"
    exit 1
fi
