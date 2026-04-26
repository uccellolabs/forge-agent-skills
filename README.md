# Laravel Forge Agent Skills

A collection of AI agent skills to automate the complete lifecycle of sites on [Laravel Forge](https://forge.laravel.com): provisioning, Git setup, database, SSL, and DNS configuration on OVHcloud.

Compatible with **Cursor** (automatic discovery) and **Claude** (Desktop Projects / Claude Code).

---

## What you can say to the agent

Once the skills are installed, describe what you want in plain language. The agent picks the right skill and executes the workflow automatically.

### Deploy a site

```
"Deploy this Laravel project to my Forge server"
"Provision a new site monsite.com with a database and SSL"
"Create a Forge site for this folder, link it to GitHub and enable SSL"
"Deploy this Next.js project to Forge on the production server"
```

### Configure DNS

```
"Configure DNS on OVH to point monsite.com to my Forge server"
"Create an A record for app.monsite.com on OVHcloud"
"Check if DNS has propagated for nordvik.uccello.io"
```

### Manage servers & sites

```
"Check Nginx and PHP status on my Forge server"
"Show me the deployment logs for example.com"
"Restart PHP-FPM on the production server"
"Run php artisan migrate on example.com"
"Sync the .env file with the server"
```

### SSL & Git

```
"Enable Let's Encrypt SSL on monsite.com"
"Create a GitHub repo for this project and link it to Forge"
"Set up auto-deploy on git push for this site"
```

### Setup & authentication

```
"Install and configure the Forge CLI on my machine"
"Authenticate me to Forge with my API token"
"Configure the SSH key to access the Forge server"
```

---

## Skills included

| Skill | What the agent can do |
|---|---|
| [`forge-cli-setup`](./forge-cli-setup/) | Install Forge CLI, authenticate, configure SSH, switch servers |
| [`forge-cli-servers`](./forge-cli-servers/) | Monitor Nginx/PHP/DB/daemons, view logs, restart services, SSH |
| [`forge-cli-sites`](./forge-cli-sites/) | Deploy sites, sync `.env`, view logs, run remote commands |
| [`forge-api-provision`](./forge-api-provision/) | Create sites, databases, link Git repos, issue SSL via Forge API |
| [`forge-deploy-automation`](./forge-deploy-automation/) | Full automation — site + Git + DB + SSL + deploy in one run |
| [`ovh-dns-forge`](./ovh-dns-forge/) | Configure OVH DNS zones via OVHcloud MCP |

---

## Installation

### Cursor

Skills are discovered automatically from `~/.cursor/skills/`. Install with one command:

```bash
git clone https://github.com/uccellolabs/forge-agent-skills ~/.cursor/skills/forge-agent-skills
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

The install script creates symlinks in `~/.cursor/skills/` so Cursor picks up each skill individually.

To install a single skill:

```bash
# Example: only the deploy automation skill
ln -s ~/.cursor/skills/forge-agent-skills/forge-deploy-automation \
      ~/.cursor/skills/forge-deploy-automation
```

### Claude Desktop

1. Open **Claude Desktop** → **Projects** → create or open a project
2. Click **Add content** → paste the content of the relevant `SKILL.md` file(s)
3. The agent will follow the skill instructions within that project

For full coverage, add `forge-deploy-automation/SKILL.md` + `forge-api-provision/SKILL.md`.

### Claude Code

Add a reference to the skills in your `CLAUDE.md`:

```bash
cat >> CLAUDE.md << 'EOF'

## Agent Skills — Laravel Forge

For Forge deployments, follow the instructions in:
- ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/SKILL.md
- ~/.cursor/skills/forge-agent-skills/forge-api-provision/SKILL.md
- ~/.cursor/skills/forge-agent-skills/ovh-dns-forge/SKILL.md
EOF
```

---

## Prerequisites

Install the required tools before using the skills:

```bash
# Laravel Forge CLI
composer global require laravel/forge-cli
forge login --token=your-forge-api-token

# GitHub CLI (for GitHub-based Git setup)
brew install gh && gh auth login

# GitLab CLI (for GitLab-based Git setup)
brew install glab && glab auth login

# jq (JSON processing used by automation scripts)
brew install jq
```

### OVHcloud MCP (for DNS management)

Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "ovhcloud": {
      "url": "https://mcp.eu.ovhcloud.com/mcp",
      "transport": "http"
    }
  }
}
```

Restart Cursor — authentication is handled automatically via OAuth2 on first use.

### Required accounts & tokens

| Service | Where to get it |
|---|---|
| **Forge API Token** | [forge.laravel.com/profile/api](https://forge.laravel.com/profile/api) |
| **GitHub** | Authenticate via `gh auth login` |
| **GitLab** | Authenticate via `glab auth login` |
| **OVHcloud** | OAuth2 prompt on first MCP call |

---

## Deployment rules

- **Never rsync** — all deployments go through Git
- **SSL is mandatory** on every site, without exception
- DNS must be propagated before requesting a Let's Encrypt certificate

---

## License

MIT
