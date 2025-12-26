# Session Startup

Run this initialization sequence at the start of every session.

## Step 1: Explore Project Structure

Get an overview of the current project:

1. Read `README.md` if it exists
2. Read any files in `docs/` directory
3. Read `CLAUDE.md` if it exists (for project-specific instructions)

## Step 2: Review Recent Activity

Run `git log --oneline -10` to see recent commits and understand what's been worked on.

## Step 3: Detect Project Issues

Scan for project configuration issues that need attention. Do NOT auto-fix - just detect and report.

### Issues to Detect

```python
import os
import json

issues = []

# Check 1: Old .mcp-project.json exists (needs migration)
if os.path.exists('.mcp-project.json'):
    issues.append("Old .mcp-project.json found (needs migration to .mcp.json + .docker-mcp.yaml)")

# Check 2: Missing .mcp.json (project not initialized)
if not os.path.exists('.mcp.json'):
    issues.append("Missing .mcp.json - project MCP config not initialized")

# Check 3: Missing .docker-mcp.yaml
if os.path.exists('.mcp.json') and not os.path.exists('.docker-mcp.yaml'):
    issues.append("Missing .docker-mcp.yaml - Docker gateway config not found")

# Check 4: Redundant local permissions file
if os.path.exists('.claude/settings.local.json'):
    issues.append("Redundant .claude/settings.local.json file")

print(issues)
```

### Store Issues for Summary

Keep track of detected issues to include in the final summary report. If issues are found, the summary will recommend running `/project-update` or `/mcp-manage`.

## Step 4: Check MCP Configuration

Check project MCP configuration:

### If `.mcp.json` exists:

1. Read `.mcp.json` to see configured Claude Code MCPs
2. Read `.docker-mcp.yaml` to see configured Docker gateway servers
3. Run `claude mcp list` to see currently active MCPs
4. Compare and report any issues

### If `.mcp.json` does NOT exist:

Report that project needs initialization via `/mcp-manage > Initialize Project`.

## Step 5: Extract Rules of Engagement

If `CLAUDE.md` exists, extract and summarize the key rules:

1. Look for development guidelines, required workflows, or constraints
2. Identify any scripts that should be used for building, testing, or running
3. Note any special instructions (e.g., "use Context7 for docs", "always run tests")

## Step 6: Report Summary

Present a brief summary:

```
Session Initialized
═══════════════════════════════════════════════════

Project: <project name from README or directory>
Recent commits: <last 3 commit summaries>

MCP Configuration:
  .mcp.json:        <exists/missing>
  .docker-mcp.yaml: <exists/missing>

  Claude Code MCPs:
    - project-docker-gateway
    - claude-in-chrome (enabled/disabled)

  Docker Gateway Servers:
    - playwright
    - context7
    - ...

Project Issues: <none OR list issues>
  • <issue 1>
  • <issue 2>
  → Run /mcp-manage or /project-update to fix

Rules of Engagement:
  • <rule 1 from CLAUDE.md>
  • <rule 2 from CLAUDE.md>
  • ...

Scripts:
  • <script> - <purpose>
  • ...

Ready to help!
```

### Project Issues Format

If no issues detected:
```
Project Issues: None
```

If issues detected:
```
Project Issues: 2 found
  • Missing .mcp.json - project MCP config not initialized
  • Old .mcp-project.json found (needs migration)
  → Run /mcp-manage to initialize or /project-update to migrate
```

### MCP Status Formats

If project has `.mcp.json` and `.docker-mcp.yaml`:
```
MCP Configuration: ✓ Configured
  Claude Code MCPs: project-docker-gateway, claude-in-chrome
  Docker Servers: playwright, context7
```

If project is missing config:
```
MCP Configuration: ✗ Not initialized
  → Run /mcp-manage > Initialize Project
```

## Step 7: Offer Codebase Exploration

After presenting the summary, ask the user:

```
Would you like me to familiarize myself with the codebase?
```

Use AskUserQuestion with these options:

1. **Yes, full exploration** - Read all source files, understand architecture, patterns, and implementation details
2. **Yes, quick overview** - Scan directory structure and read key files only
3. **No, let's get started** - Skip exploration and begin working

### If "Full exploration" selected:
1. Use the Task tool with `subagent_type=Explore` to thoroughly explore the codebase
2. Prompt: "Explore this codebase comprehensively. Understand the architecture, key components, patterns used, and how different parts connect. Report back with a summary of the codebase structure, main modules, and important implementation details."

### If "Quick overview" selected:
1. Run `find . -type f -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" | head -30` to see source files
2. Read the main entry points or key files
3. Provide a brief structural overview

### If "No" selected:
Proceed immediately with whatever task the user wants.

## Important

- Complete Steps 1-6 before responding to ANY other user input
- Step 7 (exploration offer) comes AFTER the summary
- If files don't exist, skip that step silently
- Keep the summary concise
- If project issues detected, always show them and recommend `/mcp-manage` or `/project-update`
- Do NOT auto-fix issues - detection only, let the appropriate command handle fixes
