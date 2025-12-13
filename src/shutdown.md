# Session Shutdown

Run this when ending a session to clean up project resources.

## Step 1: Stop Project Gateway

If `.mcp-project.json` has a `port` field, stop the dedicated gateway:

### Find and Stop Gateway Process

1. Read the `port` value from `.mcp-project.json`
2. Find the gateway process:
   ```bash
   lsof -i :<port> -t
   ```
3. If a process is found, kill it:
   ```bash
   kill <pid>
   ```
4. Verify it stopped:
   ```bash
   lsof -i :<port> | grep LISTEN
   ```

### Alternative: Kill by Pattern

If the above doesn't work, try:
```bash
pkill -f "docker mcp gateway.*--port=<port>"
```

### No Gateway Running

If no gateway is running on the configured port, report that it was already stopped.

### No Port Configured

If `.mcp-project.json` has no `port` field, skip this step (shared gateway persists).

## Step 2: Report Status

Present a brief shutdown summary:

```
Session Shutdown
═══════════════════════════════════════════════════

Gateway: <status>
  - Stopped gateway on port <port>
  - OR: No dedicated gateway was running
  - OR: Using shared gateway (no action needed)

Session ended. See you next time!
```

## Step 3: Offer to Commit Changes (Optional)

If there are uncommitted changes:

```bash
git status --porcelain
```

If changes exist, ask:
```
You have uncommitted changes. Would you like to commit before ending?
```

Use AskUserQuestion with options:
1. **Yes, commit changes** - Run through commit workflow
2. **No, leave as is** - End session without committing

## Important

- Always check for gateway before attempting to stop
- Don't error if gateway isn't running
- The shared MCP_DOCKER gateway should NOT be stopped (it persists across sessions)
- Only stop gateways on ports defined in .mcp-project.json
