# Project Instructions

## MCP Configuration Check

At the start of each session, check if `.mcp-project.json` exists in the project root. If it does:
1. Read the file to see which MCPs should be enabled for this project
2. Run `claude mcp list` to see what's currently enabled
3. If there's a mismatch, inform the user: "This project expects MCPs: X, Y but currently enabled: A, B. Run `/mcp-manage` to configure."

The user can run `/mcp-manage` anytime to:
- Enable/disable MCPs for this project
- Discover new MCPs from the Docker catalog
- Save current MCP config to the project

## New Conversation Initialization

When starting a new conversation or after a conversation restart, proactively:

1. **Explore Project Structure**: Use the Explore agent to understand the codebase layout, key directories, and file organization
2. **Review Architecture**: Read existing documentation (README.md, architecture docs) to understand the design patterns, tech stack, and overall system design
3. **Understand Testing**:
   - Read testing_strategy.md in the docs directory.
   - Identify test frameworks in use (pytest, Playwright, etc.)
   - Review how tests are organized and run
   - Check test configuration files (pytest.ini, playwright.config.ts, etc.)
   - Note testing patterns and conventions used in the codebase
4. **Check Recent Changes**: Review recent commits and git status to understand current development focus

This ensures continuity and prevents confusion about project conventions across conversation restarts.

## Documentation

- Always use Context7 MCP to fetch the latest library documentation instead of relying on training data
- When discussing or implementing features with external libraries, fetch current docs first
- Verify API changes and new features by checking Context7 before making assumptions

## testing
- always add unit/api/e2e tests as new features are added.s
- always update unit/api/e2e tests after code has been successfully modified.

## Documentation Maintenance

Proactively keep project documentation current:

- **After significant changes**: Use the docs-architect agent to update architecture documentation, README.md, and technical guides
- **New features**: Document architecture decisions, design patterns, and implementation details
- **API changes**: Update API documentation and integration guides
- **Architecture updates**: Maintain accurate diagrams and explanations of system design
- **Onboarding**: Use tutorial-engineer agent to create or update onboarding guides when needed

The goal is to ensure documentation evolves with the codebase and remains a reliable source of truth.

- Always maintain a read me file in GitHub format that would allow a user to reproduce the project.


## Browser Testing

- Use Playwright MCP for browser automation and testing tasks
- if you use playwright You Must use context7 to learn best practices. you must have done this at least once before writing or debugging any tests
- Prefer Playwright for cross-browser testing
- Use Chrome DevTools when straightforward debugging is not working for deep debugging and performance analysis.

## Git
- the project director is a git repository which you should maintain
- the repository should be periodically pushed to GitHub

## Build Run Test Scripts
- Always create, and maintain build scripts that allow the project to be built from the ground up.  this might include updating files on aws.
- Always create and maintain a run script it allows the project to be run. this might be simple script interfaces that allow interfaces to remote apis
- Always create and maintain a run test scripts that allow all tests to be run and verified

## Coding
- Always search context7 for the latest documentation on apis, infrastructure, libraries, best practices before coding anything.
- Inform the user what documentation you have digested and what documentation you are missing before starting any coding.
