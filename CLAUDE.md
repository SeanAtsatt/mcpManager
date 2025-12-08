# Project Instructions

## MCP Configuration
On session start, check `.mcp-project.json` against `docker mcp server ls`. If mismatched, suggest `/mcp-manage`.

## Session Initialization
On new conversations: explore codebase structure, read README.md and docs/, review recent git commits.

## Development Practices
- Use Context7 MCP for current library/API documentation before coding
- Add/update tests when adding or modifying features
- Keep README.md and docs/ current with code changes
- Use Playwright MCP for browser automation; check Context7 for best practices

## Project Maintenance
- Maintain build.sh, run.sh, test.sh scripts
- Push to GitHub after significant changes

## Scripts
- `./scripts/build.sh` - Validate source files
- `./scripts/test.sh` - Run test suite
- `./scripts/setup.sh` - Install to system
- `./scripts/run.sh` - Interactive CLI
