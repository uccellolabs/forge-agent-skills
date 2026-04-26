# forge-deploy-automation

Agent skill — Automate the complete Laravel Forge site lifecycle: create site, set up Git (GitHub or GitLab), create database, configure deployment script, enable SSL, and trigger the first deploy.

**Rule: never rsync. All deployments go through Git.**

---

## What you can say to the agent

```
"Déploie ce projet sur mon serveur Forge"
"Provisionnne un nouveau site monsite.com avec base de données et SSL"
"Crée le dépôt GitHub pour ce projet et lie-le à Forge"
"Met en place l'auto-deploy sur git push pour monsite.com"
"Ce projet n'est pas encore sur Git, crée un dépôt GitLab et déploie-le"
"Configure le déploiement complet pour ce projet Laravel"
"Ajoute le SSL sur monsite.com"
"Deploy this static site to Forge with Let's Encrypt"
```

The agent detects the project type automatically (Laravel, Symfony, WordPress, Next.js, Nuxt.js, Node.js, static HTML) and generates an appropriate deployment script.

---

## Installation

### Cursor

```bash
ln -s ~/.cursor/skills/forge-agent-skills/forge-deploy-automation \
      ~/.cursor/skills/forge-deploy-automation

# Or install all skills
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

### Claude Desktop

1. Open a Claude Project → **Add content**
2. Paste the content of [`SKILL.md`](./SKILL.md)

### Claude Code

```markdown
## Forge Deploy Automation
~/.cursor/skills/forge-agent-skills/forge-deploy-automation/SKILL.md
```

---

## Prerequisites

```bash
# Forge CLI
composer global require laravel/forge-cli
forge login --token=your-forge-api-token

# GitHub CLI
brew install gh && gh auth login

# GitLab CLI
brew install glab && glab auth login

# jq
brew install jq
```

DNS must point to your Forge server before SSL can be issued.
Use [`ovh-dns-forge`](../ovh-dns-forge/) to configure DNS if your domain is on OVHcloud.

---

## Automatic project type detection

| Detected signal | Type | Deployment script |
|---|---|---|
| `artisan` | Laravel | composer + migrate + cache + FPM reload |
| `symfony.lock` / `bin/console` | Symfony | composer + doctrine migrate + cache:clear |
| `wp-login.php` | WordPress | composer + FPM reload |
| `next.config.*` | Next.js | npm ci + build + pm2 |
| `nuxt.config.*` | Nuxt.js | npm ci + build + pm2 |
| `package.json` | Node.js | npm ci + pm2 |
| `index.html` | Static | git pull only |
| `composer.json` | PHP generic | composer + FPM reload |

Override detection with `--type laravel` (or `symfony`, `nextjs`, `static`, etc.).

---

## Scripts included

| Script | Purpose |
|---|---|
| [`provision.sh`](./provision.sh) | Full workflow — site + database + Git + SSL + deploy |
| [`git-setup.sh`](./git-setup.sh) | Git only — init, create remote repo, push, link to Forge |
| [`ssl.sh`](./ssl.sh) | SSL only — Let's Encrypt on an existing Forge site |

---

## Manual reference

```bash
# Full provisioning from a local folder (agent creates GitHub/GitLab repo)
bash provision.sh \
  --domain monsite.com \
  --local-path /path/to/project \
  --server-id 12345

# Full provisioning with existing Git repo
bash provision.sh \
  --domain monsite.com \
  --repo username/repo-name \
  --branch main \
  --server-id 12345

# With database
bash provision.sh \
  --domain monsite.com \
  --local-path /path/to/project \
  --server-id 12345 \
  --db monsite_db --db-user monsite_user --db-pass secret

# Git setup only (site already exists)
bash git-setup.sh --site monsite.com

# SSL only (site already exists)
bash ssl.sh --site monsite.com
```

---

## Validation checklist

```
- [ ] forge site:list → new site appears
- [ ] GitHub/GitLab repo exists and is linked
- [ ] git push → auto-deploy triggered
- [ ] curl -sI http://monsite.com  → 301 HTTPS
- [ ] curl -sI https://monsite.com → HTTP/2 200
- [ ] forge deploy:logs           → success
```

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
