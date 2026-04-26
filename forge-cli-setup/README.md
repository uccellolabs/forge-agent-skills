# forge-cli-setup

Agent skill — Install, authenticate, and configure the [Laravel Forge CLI](https://github.com/laravel/forge-cli).

Triggers automatically when you ask the agent to install Forge CLI, authenticate, configure SSH, or switch servers.

---

## Prerequisites

### PHP 8.0+

```bash
# macOS
brew install php

# Verify
php --version
```

### Composer (global)

```bash
# macOS
brew install composer

# Or via the official installer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```

### Forge API Token

Generate one at: [forge.laravel.com/profile/api](https://forge.laravel.com/profile/api)

---

## Installation

### Cursor

```bash
# Install this skill only
ln -s ~/.cursor/skills/forge-agent-skills/forge-cli-setup \
      ~/.cursor/skills/forge-cli-setup

# Or install all skills at once
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

Once installed, the agent reads this skill automatically when you mention `forge login`, `forge cli`, `FORGE_API_TOKEN`, or first-time setup.

### Claude Desktop

1. Open a Claude Project → **Add content**
2. Paste the content of [`SKILL.md`](./SKILL.md)
3. The agent will follow the setup instructions in that project

### Claude Code

Add to your `CLAUDE.md`:

```markdown
## Forge CLI Setup
For Forge CLI installation and authentication, follow:
~/.cursor/skills/forge-agent-skills/forge-cli-setup/SKILL.md
```

---

## What this skill covers

- **Installation** — `composer global require laravel/forge-cli`
- **Authentication** — `forge login`, `forge login --token`, `FORGE_API_TOKEN`
- **SSH configuration** — `forge ssh:configure`, `forge ssh:test`
- **Server selection** — `forge server:list`, `forge server:switch`
- **Global CLI options** — non-interactive mode, verbosity, quiet mode

---

## Quick reference

```bash
# Install
composer global require laravel/forge-cli

# Authenticate
forge login --token=your-api-token

# Configure SSH
forge ssh:configure

# Switch server
forge server:switch production

# Verify
forge server:list
forge site:list
```

Token is stored in `~/.laravel-forge/config.json` after login.

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
