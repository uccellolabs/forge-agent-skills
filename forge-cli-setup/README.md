# forge-cli-setup

Agent skill — Install, authenticate, and configure the [Laravel Forge CLI](https://github.com/laravel/forge-cli).

---

## What you can say to the agent

```
"Install and configure the Forge CLI on my machine"
"Authenticate me to Forge with my API token"
"Configure the SSH key to access the Forge server"
"Which Forge server am I currently on?"
"Switch to the production server"
"Verify that I have access to Forge"
```

The agent will guide you through installation, authentication, SSH key setup, and server selection automatically.

---

## Installation

### Cursor

```bash
ln -s ~/.cursor/skills/forge-agent-skills/forge-cli-setup \
      ~/.cursor/skills/forge-cli-setup

# Or install all skills at once
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

### Claude Desktop

1. Open a Claude Project → **Add content**
2. Paste the content of [`SKILL.md`](./SKILL.md)

### Claude Code

```markdown
## Forge CLI Setup
~/.cursor/skills/forge-agent-skills/forge-cli-setup/SKILL.md
```

---

## Prerequisites

### PHP 8.0+

```bash
brew install php
php --version
```

### Composer

```bash
brew install composer
```

### Forge API Token

Generate at: [forge.laravel.com/profile/api](https://forge.laravel.com/profile/api)

---

## Manual reference

```bash
# Install Forge CLI
composer global require laravel/forge-cli

# Authenticate
forge login --token=your-api-token

# Configure SSH key on server
forge ssh:configure
forge ssh:test

# Switch server
forge server:list
forge server:switch production

# Verify everything works
forge site:list
```

Token is stored in `~/.laravel-forge/config.json` after login.

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
