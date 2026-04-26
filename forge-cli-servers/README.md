# forge-cli-servers

Agent skill — Manage Laravel Forge servers via CLI: monitor resources, view logs, restart services, connect via SSH.

---

## What you can say to the agent

```
"Vérifie le statut de Nginx sur mon serveur Forge"
"Montre-moi les logs PHP en temps réel"
"Redémarre PHP-FPM sur le serveur de production"
"Est-ce que la base de données tourne correctement ?"
"Affiche les logs d'erreur Nginx"
"Connecte-moi en SSH au serveur"
"Ouvre un shell MySQL sur la base de données my_db"
"Mon daemon queue est tombé, redémarre-le"
```

The agent checks service health, streams logs, restarts what's needed, and connects via SSH without you needing to remember any command.

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

## Prerequisites

- **Forge CLI** installed and authenticated — see [`forge-cli-setup`](../forge-cli-setup/)
- **SSH key configured** on the target server:

```bash
forge ssh:configure && forge ssh:test
```

---

## Manual reference

```bash
# Switch server
forge server:switch production

# Service status
forge nginx:status
forge php:status 8.3
forge database:status
forge daemon:status

# Logs
forge nginx:logs            # error log
forge nginx:logs access     # access log
forge php:logs 8.3
forge daemon:logs --follow  # live stream

# Restart services
forge nginx:restart
forge php:restart 8.3
forge database:restart
forge daemon:restart

# SSH
forge ssh
forge ssh --user=root

# Database shell
forge database:shell my_db
```

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
