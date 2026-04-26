# forge-cli-servers

Agent skill — Manage Laravel Forge servers via CLI: monitor resources, view logs, restart services, connect via SSH.

Triggers automatically when you ask about server status, Nginx, PHP, database, daemon management, or SSH access on Forge.

---

## Prerequisites

- **Forge CLI** installed and authenticated — see [`forge-cli-setup`](../forge-cli-setup/)
- **SSH key configured** on the target server:

```bash
forge ssh:configure
forge ssh:test
```

---

## Installation

### Cursor

```bash
ln -s ~/.cursor/skills/forge-agent-skills/forge-cli-servers \
      ~/.cursor/skills/forge-cli-servers

# Or install all skills
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

### Claude Desktop

1. Open a Claude Project → **Add content**
2. Paste the content of [`SKILL.md`](./SKILL.md)

### Claude Code

```markdown
## Forge Server Management
~/.cursor/skills/forge-agent-skills/forge-cli-servers/SKILL.md
```

---

## What this skill covers

| Category | Commands |
|---|---|
| **Navigation** | `server:list`, `server:current`, `server:switch` |
| **Status** | `nginx:status`, `database:status`, `php:status`, `daemon:status` |
| **Logs** | `nginx:logs`, `database:logs`, `php:logs`, `daemon:logs --follow` |
| **Restart** | `nginx:restart`, `database:restart`, `php:restart`, `daemon:restart` |
| **SSH** | `forge ssh`, `forge ssh --user=root` |
| **DB shell** | `forge database:shell` |

---

## Quick reference

```bash
# Switch to the right server first
forge server:switch production

# Check all service health
forge nginx:status
forge php:status 8.3
forge database:status

# Stream logs live
forge nginx:logs
forge daemon:logs --follow

# Connect via SSH
forge ssh
forge ssh --user=root

# Open a DB shell
forge database:shell my_db
```

---

## Typical troubleshooting workflow

```bash
forge server:switch <name>
forge nginx:status           # Is Nginx running?
forge nginx:logs             # Any errors?
forge nginx:restart          # Restart if needed
forge site:logs example.com  # App-level errors
```

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
