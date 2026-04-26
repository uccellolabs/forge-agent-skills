# Laravel Forge Agent Skills

A collection of AI agent skills to automate the complete lifecycle of sites on [Laravel Forge](https://forge.laravel.com): provisioning, Git setup, database, SSL, and DNS configuration on OVHcloud.

Compatible with **Cursor** (automatic discovery) and **Claude** (Desktop Projects / Claude Code).

---

## What you can say to the agent

Once the skills are installed, describe what you want in plain language. The agent picks the right skill and executes the workflow automatically.

### Deploy a site

```
"Déploie ce projet Laravel sur mon serveur Forge"
"Provisionnne un nouveau site monsite.com avec base de données et SSL"
"Crée un site Forge pour ce dossier, lie-le à GitHub et active le SSL"
"Deploy this Next.js project to Forge on server production"
```

### Configure DNS

```
"Configure le DNS sur OVH pour pointer monsite.com vers mon serveur Forge"
"Crée un enregistrement A pour app.monsite.com sur OVHcloud"
"Vérifie si le DNS a propagé pour nordvik.uccello.io"
```

### Manage servers & sites

```
"Vérifie le statut de Nginx et PHP sur mon serveur Forge"
"Montre-moi les logs de déploiement de example.com"
"Redémarre PHP-FPM sur le serveur de production"
"Lance php artisan migrate sur example.com"
"Synchronise le fichier .env avec le serveur"
```

### SSL & Git

```
"Active le SSL Let's Encrypt sur monsite.com"
"Crée un dépôt GitHub pour ce projet et lie-le à Forge"
"Met en place l'auto-deploy sur git push pour ce site"
```

### Setup & authentication

```
"Installe et configure la Forge CLI sur ma machine"
"Connecte-moi à Forge avec mon token API"
"Configure la clé SSH pour accéder au serveur via Forge"
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
