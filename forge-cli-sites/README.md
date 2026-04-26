# forge-cli-sites

Agent skill — Manage Laravel Forge sites via CLI: deploy, manage environment variables, view logs, run remote commands, use Tinker.

---

## What you can say to the agent

```
"Deploy example.com on Forge"
"Show me the last deployment logs"
"Sync the local .env file with the server"
"Run php artisan migrate --force on example.com"
"Stream the application logs in real time"
"Open a Tinker session on example.com"
"Restart the queue workers"
"Check that the deployment succeeded"
```

---

## Installation

### Cursor

```bash
ln -s ~/.cursor/skills/forge-agent-skills/forge-cli-sites \
      ~/.cursor/skills/forge-cli-sites

# Or install all skills
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

### Claude Desktop

1. Open a Claude Project → **Add content**
2. Paste the content of [`SKILL.md`](./SKILL.md)

### Claude Code

```markdown
## Forge Sites & Deployments
~/.cursor/skills/forge-agent-skills/forge-cli-sites/SKILL.md
```

---

## Prerequisites

- **Forge CLI** installed and authenticated — see [`forge-cli-setup`](../forge-cli-setup/)
- **SSH key configured** (required for `forge command`, `forge tinker`):

```bash
forge ssh:configure && forge ssh:test
```

---

## Manual reference

```bash
# List sites
forge site:list

# Deploy
forge deploy example.com
forge deploy:logs

# Environment variables
forge env:pull example.com          # download from server
forge env:push example.com          # push to server

# Application logs
forge site:logs example.com --follow

# Run remote commands
forge command example.com --command="php artisan migrate --force"
forge command example.com --command="php artisan queue:restart"
forge command example.com --command="php artisan about"

# Tinker (Laravel REPL)
forge tinker example.com

# Open in Forge dashboard
forge open example.com
```

> After pushing `.env`, redeploy if using config cache or queue workers.

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
