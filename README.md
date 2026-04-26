# Laravel Forge Agent Skills

A collection of AI agent skills to automate the complete lifecycle of sites on [Laravel Forge](https://forge.laravel.com): provisioning, Git setup, database, SSL, and DNS configuration on OVHcloud.

Compatible with **Cursor** (automatic discovery) and **Claude** (Desktop Projects / Claude Code).

---

## Skills included

| Skill | Description |
|---|---|
| [`forge-cli-setup`](./forge-cli-setup/) | Install, authenticate, and configure the Forge CLI |
| [`forge-cli-servers`](./forge-cli-servers/) | Manage servers — Nginx, PHP, databases, daemons |
| [`forge-cli-sites`](./forge-cli-sites/) | Deploy sites, manage `.env`, view logs, run commands |
| [`forge-api-provision`](./forge-api-provision/) | Provision sites, databases, Git repos, and SSL via Forge REST API |
| [`forge-deploy-automation`](./forge-deploy-automation/) | Full automation — create site + Git + DB + SSL + deploy in one run |
| [`ovh-dns-forge`](./ovh-dns-forge/) | Configure OVH DNS zones to point to Forge via OVHcloud MCP |

---

## Prerequisites

### Required tools

```bash
# Laravel Forge CLI
composer global require laravel/forge-cli

# GitHub CLI (for GitHub-based Git setup)
brew install gh
gh auth login

# GitLab CLI (for GitLab-based Git setup)
brew install glab
glab auth login

# jq (JSON processing)
brew install jq

# PHP 8.0+ (required by Forge CLI)
brew install php
```

### Required accounts & tokens

| Service | Where to get it |
|---|---|
| **Forge API Token** | [forge.laravel.com/profile/api](https://forge.laravel.com/profile/api) |
| **GitHub account** | [github.com](https://github.com) — authenticate via `gh auth login` |
| **GitLab account** | [gitlab.com](https://gitlab.com) — authenticate via `glab auth login` |
| **OVHcloud account** | [ovhcloud.com](https://ovhcloud.com) — for DNS management |

### Set your Forge API token

```bash
# Option A: environment variable (recommended for CI/CD)
export FORGE_API_TOKEN=your-token-here

# Option B: via the CLI (stores to ~/.laravel-forge/config.json)
forge login --token=your-token-here
```

---

## Installation

### Cursor

Skills are discovered automatically from `~/.cursor/skills/`. Install with one command:

```bash
git clone https://github.com/uccello/forge-agent-skills ~/.cursor/skills/forge-agent-skills
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

The install script creates symlinks in `~/.cursor/skills/` so Cursor picks up each skill individually.

To install a single skill:

```bash
# Example: only the deploy automation skill
ln -s ~/.cursor/skills/forge-agent-skills/forge-deploy-automation \
      ~/.cursor/skills/forge-deploy-automation
```

Once installed, the agent will automatically read the appropriate skill when you ask it to deploy a site, manage DNS, configure SSL, etc.

### Claude Desktop (Projects)

1. Open **Claude Desktop** → **Projects** → create a new project (or open an existing one)
2. Click **Add content** → paste the content of the relevant `SKILL.md` file(s)
3. The agent will follow the skill instructions within that project

Recommended: add `forge-deploy-automation/SKILL.md` for full coverage, or pick individual skills.

### Claude Code

Add a reference to the skills from your `CLAUDE.md`:

```bash
# From your project root
cat >> CLAUDE.md << 'EOF'

## Agent Skills

For Forge deployments, follow the instructions in:
- ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/SKILL.md
- ~/.cursor/skills/forge-agent-skills/forge-api-provision/SKILL.md
- ~/.cursor/skills/forge-agent-skills/ovh-dns-forge/SKILL.md
EOF
```

Or copy the skill content directly into your `CLAUDE.md`.

---

## Quick start — Deploy a site end-to-end

```bash
# 1. Point DNS to your Forge server (via OVHcloud MCP or manually)

# 2. Run the full provisioning script
bash ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/provision.sh \
  --domain monsite.com \
  --local-path /path/to/project \
  --server-id 12345

# The script handles:
# ✓ Site creation (Forge API)
# ✓ Project type detection (Laravel, Symfony, Next.js, static, etc.)
# ✓ Git repo creation (GitHub or GitLab) + link to Forge
# ✓ Deployment script generation (adapted to the project type)
# ✓ Let's Encrypt SSL (mandatory)
# ✓ Initial deployment
```

Or just describe what you want to the agent — it will pick the right skill automatically.

---

## Deployment rules

- **Never rsync** — all deployments go through Git
- **SSL is mandatory** on every site, without exception
- DNS must be propagated before requesting a Let's Encrypt certificate

---

## License

MIT
