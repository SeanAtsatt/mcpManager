# Testing Strategy

## Overview

MCP Manager uses a comprehensive testing approach to ensure reliability across all components. Tests are implemented in Bash with Python helpers for JSON validation.

## Test Categories

### 1. Unit Tests

Unit tests validate individual components in isolation.

#### JSON Validation
- Registry file is valid JSON
- Project config files are valid JSON
- All required top-level keys exist

#### Schema Compliance
- All servers have required fields (`status`, `source`, `description`, etc.)
- All profiles have required fields (`description`, `mcps`)
- Field types are correct (arrays, strings, integers)

#### Syntax Validation
- Shell scripts have valid Bash syntax
- No undefined variables
- Proper quoting and escaping

### 2. Integration Tests

Integration tests verify components work together correctly.

#### Registry Operations
- Registry can be read and written
- Modifications persist correctly
- Timestamps update properly

#### Archive/Restore Flow
- MCPs can be archived with metadata
- Archived MCPs can be restored
- Archive preserves all original data

#### Profile Management
- Profiles reference valid servers
- Profile creation saves correctly
- Profile application works

#### Project Config
- Config files can be created
- Config fields can be parsed
- Apply operation works correctly

### 3. Validation Tests

Validation tests ensure data integrity.

#### Field Type Validation
- `context_tokens` are positive integers
- `command` arrays are non-empty
- `capabilities` and `tags` are arrays

#### Enum Validation
- `status` is "active" or "archived"
- `source` is valid type (docker, docker-gateway, npx, local, remote)

#### Reference Validation
- Profile MCPs reference existing servers
- No orphaned references

## Running Tests

### Full Test Suite
```bash
./scripts/test.sh
```

### Build Validation Only
```bash
./scripts/build.sh
```

### Test Output

Tests produce color-coded output:
- **Green (PASS)** - Test succeeded
- **Red (FAIL)** - Test failed with reason

Example output:
```
MCP Manager Test Suite
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Unit Tests
────────────────────────────────────────
TEST 1: Registry JSON is valid
  ✓ PASS
TEST 2: Registry has required top-level keys
  ✓ PASS
...

Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Total:  18
  Passed: 18
  Failed: 0

All tests passed!
```

## Test Environment

Tests run in an isolated temporary directory to avoid affecting the real system:
- Creates temporary `~/.config/claude-mcp/` structure
- Cleans up automatically on exit
- Does not modify real registry or configs

## Test Data

### Test Registry
A copy of `src/registry.json` is used as the base test data.

### Test Project Config
Created dynamically during tests:
```json
{
  "project": "test-project",
  "description": "Test project",
  "enabled": ["MCP_DOCKER"],
  "disabled": []
}
```

## Adding New Tests

### Adding a Unit Test
```bash
# Test X: Description
test_start "Description of what is being tested"
if [ some_condition ]; then
    test_pass
else
    test_fail "Reason for failure"
fi
```

### Adding an Integration Test
Integration tests should:
1. Set up test data in the temp environment
2. Perform the operation
3. Verify the result
4. Clean up if necessary

### Test Helper Functions

| Function | Description |
|----------|-------------|
| `test_start "desc"` | Start a new test with description |
| `test_pass` | Mark current test as passed |
| `test_fail "reason"` | Mark current test as failed |

## Continuous Integration

For CI/CD pipelines, the test script returns appropriate exit codes:
- `0` - All tests passed
- `1` - One or more tests failed

Example GitHub Actions workflow:
```yaml
- name: Run tests
  run: ./scripts/test.sh
```

## Test Coverage Goals

| Category | Target | Current |
|----------|--------|---------|
| Unit Tests | 100% of core functions | 8 tests |
| Integration Tests | All major workflows | 6 tests |
| Validation Tests | All schema constraints | 4 tests |

## Known Limitations

1. **No Claude CLI mocking** - Tests that require `claude mcp list` are skipped if Claude CLI is not available
2. **No Docker testing** - Tests don't verify Docker MCP commands actually work
3. **No UI testing** - Interactive CLI (`run.sh`) is not automatically tested

## Future Improvements

- [ ] Add mock for Claude CLI commands
- [ ] Add performance benchmarks
- [ ] Add fuzz testing for JSON parsing
- [ ] Add end-to-end tests with Docker
