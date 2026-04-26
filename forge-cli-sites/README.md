# forge-cli-sites

Agent skill — Manage Laravel Forge sites via CLI: deploy, manage environment variables, view logs, run remote commands, use Tinker.

Triggers automatically when you ask to deploy a site, push `.env` vars, check deployment logs, or run artisan commands on Forge.

---

## Prerequisites

- **Forge CLI** installed and authenticated — see [`forge-cli-setup`](../forge-cli-setup/)
- **SSH key configured** on the target server (required for `forge command`, `forge tinker`, `forge ssh`):

```bash
forge ssh:configure
forge ssh:test
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

## What this skill covers

| Feature | Commands |
|---|---|
| **Deploy** | `forge deploy`, `forge deploy example.com` |
| **Deployment logs** | `forge deploy:logs` |
| **Environment** | `forge env:pull`, `forge env:push` |
| **App logs** | `forge site:logs`, `forge site:logs --follow` |
| **Remote commands** | `forge command example.com --command="php artisan migrate"` |
| **Tinker** | `forge tinker example.com` |
| **Dashboard** | `forge open example.com` |

---

## Quick reference

```bash
# List all sites on active server
forge site:list

# Deploy
forge deploy example.com
forge deploy:logs

# Sync .env
forge env:pull example.com          # Download from server
forge env:push example.com          # Push to server
forge env:push example.com .env.production

# Stream app logs
forge site:logs example.com --follow

# Run remote commands
forge command example.com --command="php artisan migrate --force"
forge command example.com --command="php artisan queue:restart"

# Laravel Tinker (interactive REPL)
forge tinker example.com
```

---

## Common deployment workflow

```bash
# 1. Target the right server
forge server:switch production

# 2. Sync environment variables if changed
forge env:push example.com .env.production

# 3. Deploy
forge deploy example.com

# 4. Watch deployment output
forge deploy:logs

# 5. Verify
forge command example.com --command="php artisan about"
```

> After pushing `.env` vars, redeploy if using config cache or queue workers.

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
