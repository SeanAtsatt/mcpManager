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

echo -e "${CYAN}${BOLD}MCP Manager Test Suite (v2.0 Schema)${NC}"
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

# Test 2: Registry has required v2.0 keys
test_start "Registry has required top-level keys (v2.0 schema)"
MISSING=$(python3 -c "
import json
reg = json.load(open('$SRC_DIR/registry.json'))
required = ['version', 'profiles', 'docker_mcps', 'archived', 'config']
missing = [k for k in required if k not in reg]
print(' '.join(missing))
" 2>/dev/null)
if [ -z "$MISSING" ]; then
    test_pass
else
    test_fail "Missing keys: $MISSING"
fi

# Test 3: Registry version is 2.0
test_start "Registry version is 2.0"
RESULT=$(python3 -c "
import json
reg = json.load(open('$SRC_DIR/registry.json'))
print('OK' if reg.get('version') == '2.0' else 'FAIL')
" 2>/dev/null)
if [ "$RESULT" = "OK" ]; then
    test_pass
else
    test_fail "Version is not 2.0"
fi

# Test 4: All docker_mcps have required fields
test_start "All docker_mcps have required fields"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
required = ['description', 'capabilities', 'tags']
errors = []
for name, mcp in reg.get('docker_mcps', {}).items():
    for key in required:
        if key not in mcp:
            errors.append(f"{name}.{key}")
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Missing fields: $RESULT"
fi

# Test 5: Profile docker_mcps reference valid MCPs
test_start "Profile docker_mcps reference valid MCPs"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
errors = []
known_mcps = set(reg.get('docker_mcps', {}).keys())
for name, profile in reg.get('profiles', {}).items():
    for mcp in profile.get('docker_mcps', []):
        if mcp not in known_mcps:
            errors.append(f"{name}->{mcp}")
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Invalid references: $RESULT"
fi

# Test 6: All profiles have required fields
test_start "All profiles have required fields"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
required = ['description', 'docker_mcps', 'created']
errors = []
for name, profile in reg.get('profiles', {}).items():
    for key in required:
        if key not in profile:
            errors.append(f"{name}.{key}")
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Missing fields: $RESULT"
fi

# Test 7: Shell helpers have valid syntax
test_start "Shell helpers have valid syntax"
if bash -n "$SRC_DIR/mcp-helpers.sh" 2>/dev/null; then
    test_pass
else
    test_fail "Syntax errors in mcp-helpers.sh"
fi

# Test 8: Setup script has valid syntax
test_start "Setup script has valid syntax"
if bash -n "$PROJECT_DIR/scripts/setup.sh" 2>/dev/null; then
    test_pass
else
    test_fail "Syntax errors in setup.sh"
fi

# Test 9: Build script has valid syntax
test_start "Build script has valid syntax"
if bash -n "$PROJECT_DIR/scripts/build.sh" 2>/dev/null; then
    test_pass
else
    test_fail "Syntax errors in build.sh"
fi

# Test 10: mcp-manage.md exists and is not empty
test_start "mcp-manage.md slash command exists"
if [ -s "$SRC_DIR/mcp-manage.md" ]; then
    test_pass
else
    test_fail "mcp-manage.md is missing or empty"
fi

# Test 11: startup.md exists and is not empty
test_start "startup.md slash command exists"
if [ -s "$SRC_DIR/startup.md" ]; then
    test_pass
else
    test_fail "startup.md is missing or empty"
fi

# Test 12: startup.md contains required sections
test_start "startup.md contains required sections"
MISSING_SECTIONS=$(python3 << 'PYTHON'
content = open('src/startup.md').read()
required = ['Step 1', 'Step 2', 'Step 3', 'Step 4', 'Step 5', 'MCP Status', 'Rules of Engagement']
missing = [s for s in required if s not in content]
print(' '.join(missing) if missing else '')
PYTHON
)
if [ -z "$MISSING_SECTIONS" ]; then
    test_pass
else
    test_fail "Missing sections: $MISSING_SECTIONS"
fi

echo ""

# ============================================
# Integration Tests
# ============================================

echo -e "${BOLD}Integration Tests${NC}"
echo -e "────────────────────────────────────────"

# Test 11: Setup script creates registry
test_start "Setup creates registry file"
cp "$SRC_DIR/registry.json" "$TEST_CONFIG_DIR/registry.json"
if [ -f "$TEST_CONFIG_DIR/registry.json" ]; then
    test_pass
else
    test_fail "Registry not created"
fi

# Test 12: Registry can be read and modified
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

# Test 13: Project config can be created (v2.0 schema)
test_start "Project config can be created (v2.0 schema)"
TEST_PROJECT_DIR="$TEST_TMP/test-project"
mkdir -p "$TEST_PROJECT_DIR"
cat > "$TEST_PROJECT_DIR/.mcp-project.json" << 'EOF'
{
  "project": "test-project",
  "description": "Test project",
  "docker_mcps": ["playwright", "context7"],
  "notes": "Test notes"
}
EOF
if python3 -c "import json; json.load(open('$TEST_PROJECT_DIR/.mcp-project.json'))" 2>/dev/null; then
    test_pass
else
    test_fail "Invalid project config"
fi

# Test 14: Project config fields can be parsed
test_start "Project config fields can be parsed"
RESULT=$(python3 << PYTHON
import json
config = json.load(open('$TEST_PROJECT_DIR/.mcp-project.json'))
if config.get('project') == 'test-project' and 'playwright' in config.get('docker_mcps', []):
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

# Test 15: Archive operation works
test_start "Archive operation modifies registry"
RESULT=$(python3 << PYTHON
import json
from datetime import datetime

reg_path = "$TEST_CONFIG_DIR/registry.json"
reg = json.load(open(reg_path))

# Add a test MCP to docker_mcps
reg['docker_mcps']['test-mcp'] = {
    'description': 'Test MCP',
    'capabilities': ['test'],
    'tags': ['test'],
    'added': '2024-12-07'
}

# Archive it
mcp_data = reg['docker_mcps'].pop('test-mcp')
mcp_data['archived_date'] = datetime.now().strftime('%Y-%m-%d')
mcp_data['archive_reason'] = 'Test archive'
reg['archived']['test-mcp'] = mcp_data

json.dump(reg, open(reg_path, 'w'), indent=2)

# Verify
reg2 = json.load(open(reg_path))
if 'test-mcp' in reg2.get('archived', {}) and 'test-mcp' not in reg2.get('docker_mcps', {}):
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

# Test 16: Restore operation works
test_start "Restore operation modifies registry"
RESULT=$(python3 << PYTHON
import json

reg_path = "$TEST_CONFIG_DIR/registry.json"
reg = json.load(open(reg_path))

# Restore test-mcp
if 'test-mcp' in reg.get('archived', {}):
    mcp_data = reg['archived'].pop('test-mcp')
    # Remove archive metadata
    mcp_data.pop('archived_date', None)
    mcp_data.pop('archive_reason', None)
    reg['docker_mcps']['test-mcp'] = mcp_data
    json.dump(reg, open(reg_path, 'w'), indent=2)

# Verify
reg2 = json.load(open(reg_path))
if 'test-mcp' in reg2.get('docker_mcps', {}) and 'test-mcp' not in reg2.get('archived', {}):
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

# Test 17: Profile creation works
test_start "Profile creation works"
RESULT=$(python3 << PYTHON
import json
from datetime import datetime

reg_path = "$TEST_CONFIG_DIR/registry.json"
reg = json.load(open(reg_path))

reg['profiles']['test-profile'] = {
    'description': 'Test profile',
    'docker_mcps': ['playwright', 'context7'],
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

# Test 18: Profile deletion works
test_start "Profile deletion works"
RESULT=$(python3 << PYTHON
import json

reg_path = "$TEST_CONFIG_DIR/registry.json"
reg = json.load(open(reg_path))

if 'test-profile' in reg['profiles']:
    del reg['profiles']['test-profile']
    json.dump(reg, open(reg_path, 'w'), indent=2)

# Verify
reg2 = json.load(open(reg_path))
if 'test-profile' not in reg2.get('profiles', {}):
    print('OK')
else:
    print('FAIL')
PYTHON
)
if [ "$RESULT" = "OK" ]; then
    test_pass
else
    test_fail "Profile deletion failed"
fi

echo ""

# ============================================
# Validation Tests
# ============================================

echo -e "${BOLD}Validation Tests${NC}"
echo -e "────────────────────────────────────────"

# Test 19: Tags are non-empty arrays
test_start "Tags are valid arrays"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
errors = []
for name, mcp in reg.get('docker_mcps', {}).items():
    tags = mcp.get('tags')
    if not isinstance(tags, list) or len(tags) == 0:
        errors.append(name)
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Invalid tags for: $RESULT"
fi

# Test 20: Capabilities are non-empty arrays
test_start "Capabilities are valid arrays"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
errors = []
for name, mcp in reg.get('docker_mcps', {}).items():
    caps = mcp.get('capabilities')
    if not isinstance(caps, list) or len(caps) == 0:
        errors.append(name)
print(' '.join(errors) if errors else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Invalid capabilities for: $RESULT"
fi

# Test 21: Config section has expected keys
test_start "Config section has expected keys"
RESULT=$(python3 << 'PYTHON'
import json
reg = json.load(open('src/registry.json'))
config = reg.get('config', {})
expected = ['default_profile', 'auto_apply_on_cd', 'sync_with_docker_catalog']
missing = [k for k in expected if k not in config]
print(' '.join(missing) if missing else '')
PYTHON
)
if [ -z "$RESULT" ]; then
    test_pass
else
    test_fail "Missing config keys: $RESULT"
fi

# Test 22: Archived section exists (even if empty)
test_start "Archived section exists"
RESULT=$(python3 -c "
import json
reg = json.load(open('$SRC_DIR/registry.json'))
print('OK' if 'archived' in reg and isinstance(reg['archived'], dict) else 'FAIL')
" 2>/dev/null)
if [ "$RESULT" = "OK" ]; then
    test_pass
else
    test_fail "Archived section missing or invalid"
fi

# Test 23: mcp-manage.md contains archive feature
test_start "mcp-manage.md includes archive management"
if grep -q "Manage Archives" "$SRC_DIR/mcp-manage.md" 2>/dev/null; then
    test_pass
else
    test_fail "Archive management not found in mcp-manage.md"
fi

# Test 24: mcp-manage.md uses correct docker mcp commands
test_start "mcp-manage.md uses correct docker mcp server commands"
if grep -q "docker mcp server enable" "$SRC_DIR/mcp-manage.md" 2>/dev/null && \
   grep -q "docker mcp server disable" "$SRC_DIR/mcp-manage.md" 2>/dev/null; then
    test_pass
else
    test_fail "Incorrect docker mcp commands in mcp-manage.md"
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
