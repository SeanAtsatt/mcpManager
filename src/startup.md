# Session Startup

Run this initialization sequence at the start of every session.

## Step 1: Explore Project Structure

Get an overview of the current project:

1. Read `README.md` if it exists
2. Read any files in `docs/` directory
3. Read `CLAUDE.md` if it exists (for project-specific instructions)

## Step 2: Review Recent Activity

Run `git log --oneline -10` to see recent commits and understand what's been worked on.

## Step 3: Check MCP Configuration

If `.mcp-project.json` exists in the project root:

1. Read `.mcp-project.json` to see required MCPs
2. Run `docker mcp server ls` to see currently enabled MCPs
3. Compare the two lists
4. If there's a mismatch, report it and offer to sync using `/mcp-manage`

## Step 4: Extract Rules of Engagement

If `CLAUDE.md` exists, extract and summarize the key rules:

1. Look for development guidelines, required workflows, or constraints
2. Identify any scripts that should be used for building, testing, or running
3. Note any special instructions (e.g., "use Context7 for docs", "always run tests")

## Step 5: Report Summary

Present a brief summary:

```
Session Initialized
═══════════════════════════════════════════════════

Project: <project name from README or directory>
Recent commits: <last 3 commit summaries>

MCP Status: <matched/mismatched>
  Required: <list from .mcp-project.json>
  Enabled:  <list from docker mcp server ls>

Rules of Engagement:
  • <rule 1 from CLAUDE.md>
  • <rule 2 from CLAUDE.md>
  • ...

Scripts:
  • <script> - <purpose>
  • ...

Ready to help!
```

## Step 6: Offer Codebase Exploration

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

- Complete Steps 1-5 before responding to ANY other user input
- Step 6 (exploration offer) comes AFTER the summary
- If files don't exist, skip that step silently
- Keep the summary concise
- If MCP mismatch detected, always mention it
