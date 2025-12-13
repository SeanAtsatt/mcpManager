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
import json
import os

issues = []

# Check 1: MCP config uses old schema
if os.path.exists('.mcp-project.json'):
    with open('.mcp-project.json') as f:
        config = json.load(f)
    if 'servers' in config and 'docker_mcps' not in config:
        issues.append("MCP config uses old 'servers' field")
    if 'mcps' in config and 'docker_mcps' not in config:
        issues.append("MCP config uses old 'mcps' field")
    if 'schema_version' not in config:
        issues.append("MCP config missing schema_version")

# Check 2: Redundant local permissions file
if os.path.exists('.claude/settings.local.json'):
    issues.append("Redundant .claude/settings.local.json file")

print(issues)
```

### Store Issues for Summary

Keep track of detected issues to include in the final summary report. If issues are found, the summary will recommend running `/project-update`.

## Step 4: Check MCP Configuration

If `.mcp-project.json` exists in the project root:

1. Read `.mcp-project.json` to see required MCPs
2. Run `docker mcp server ls` to see currently enabled MCPs
3. Compare the two lists
4. If there's a mismatch, report it and offer to sync using `/mcp-manage`

## Step 5: Manage Project Gateway (Multi-Project Support)

If `.mcp-project.json` has a `port` field, this project uses a **dedicated gateway** for isolated MCP configuration. This allows multiple projects to run different MCP servers simultaneously.

### Check Gateway Status

1. Read the `port` value from `.mcp-project.json`
2. Check if a gateway is already running on that port:
   ```bash
   lsof -i :<port> | grep LISTEN
   ```

### Start Gateway if Not Running

If no gateway is running on the configured port:

1. Get the server list from `docker_mcps` in `.mcp-project.json`
2. Start the gateway in background:
   ```bash
   docker mcp gateway run \
     --servers=<comma-separated-mcps> \
     --transport=sse \
     --port=<port> &
   ```
3. Wait a moment for startup, then verify it's running

### Gateway Already Running

If a gateway is already running on the port, report its status.

### No Port Configured

If `.mcp-project.json` exists but has no `port` field:
- Use the shared MCP_DOCKER gateway (current behavior)
- Sync MCPs via `docker mcp server enable/disable`

## Step 6: Extract Rules of Engagement

If `CLAUDE.md` exists, extract and summarize the key rules:

1. Look for development guidelines, required workflows, or constraints
2. Identify any scripts that should be used for building, testing, or running
3. Note any special instructions (e.g., "use Context7 for docs", "always run tests")

## Step 7: Report Summary

Present a brief summary:

```
Session Initialized
═══════════════════════════════════════════════════

Project: <project name from README or directory>
Recent commits: <last 3 commit summaries>

MCP Status: <matched/mismatched>
  Required: <list from .mcp-project.json>
  Enabled:  <list from docker mcp server ls>

Gateway: <status - see below>

Project Issues: <none OR list issues>
  • <issue 1>
  • <issue 2>
  → Run /project-update to fix

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
  • MCP config uses old 'servers' field
  • Redundant .claude/settings.local.json file
  → Run /project-update to fix
```

### Gateway Status Formats

If project has a `port` configured:
```
Gateway: Running on port 8811 (dedicated)
  Servers: playwright, context7
  Endpoint: http://localhost:8811/sse
```

If gateway was just started:
```
Gateway: Started on port 8811 (dedicated)
  Servers: playwright, context7
  Endpoint: http://localhost:8811/sse
```

If no port configured (using shared gateway):
```
Gateway: Using shared MCP_DOCKER
```

## Step 8: Offer Codebase Exploration

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

- Complete Steps 1-7 before responding to ANY other user input
- Step 8 (exploration offer) comes AFTER the summary
- If files don't exist, skip that step silently
- Keep the summary concise
- If MCP mismatch detected, always mention it
- If gateway fails to start, report the error and suggest checking Docker status
- If project issues detected, always show them and recommend `/project-update`
- Do NOT auto-fix issues - detection only, let `/project-update` handle fixes
