# Session Shutdown

Run this when ending a session to clean up and optionally commit changes.

## Overview

With the project-local architecture, the Docker gateway is managed automatically by Claude Code via `.mcp.json`. There's no need to manually stop gateways - they stop when the Claude Code session ends.

## Step 1: Check for Uncommitted Changes

```bash
git status --porcelain
```

If changes exist, proceed to Step 2. If no changes, skip to Step 3.

## Step 2: Offer to Commit Changes

If there are uncommitted changes, ask:

```
You have uncommitted changes. Would you like to commit before ending?
```

Use AskUserQuestion with options:
1. **Yes, commit changes** - Run through commit workflow
2. **No, leave as is** - End session without committing

### If "Yes, commit changes" selected:

1. Run `git status` to show what will be committed
2. Run `git diff --stat` to show change summary
3. Ask for a commit message or generate one based on changes
4. Stage and commit the changes

## Step 3: Report Session Summary

Present a brief shutdown summary:

```
Session Shutdown
═══════════════════════════════════════════════════

Changes: <committed/uncommitted/none>
  - <summary of what was done this session>

MCP Configuration:
  - Gateway will stop automatically when session ends
  - Config preserved in .mcp.json and .docker-mcp.yaml

Session ended. See you next time!
```

## Important

- The Docker gateway is managed by Claude Code and stops automatically
- No manual gateway cleanup is needed
- Focus on helping the user commit any work if desired
- Keep the summary concise
