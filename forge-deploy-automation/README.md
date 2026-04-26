# forge-deploy-automation

Agent skill — Automate the complete Laravel Forge site lifecycle: create site, set up Git (GitHub or GitLab), create database, configure deployment script, enable SSL, and trigger the first deploy — all in one run.

**Rule: never rsync. All deployments go through Git.**

Triggers automatically when you ask to deploy a site to Forge, create a GitHub/GitLab repo for a project, set up CI/CD with auto-deploy on push, or automate the full site provisioning workflow.

---

## Prerequisites

### Required tools

```bash
# Laravel Forge CLI
composer global require laravel/forge-cli
forge login --token=your-forge-api-token

# GitHub CLI (if using GitHub)
brew install gh
gh auth login

# GitLab CLI (if using GitLab)
brew install glab
glab auth login

# jq
brew install jq

# Python 3 (for JSON parsing in scripts — pre-installed on macOS)
python3 --version
```

### Forge API Token

```bash
# Option A: environment variable
export FORGE_API_TOKEN=your-token-here

# Option B: via Forge CLI (stored in ~/.laravel-forge/config.json)
forge login --token=your-token-here
```

Generate at: [forge.laravel.com/profile/api](https://forge.laravel.com/profile/api)

### DNS pre-configured

The domain must resolve to your Forge server's IP **before** running the provisioning script (Let's Encrypt requires DNS to be live).

Use the [`ovh-dns-forge`](../ovh-dns-forge/) skill to set up DNS if your domain is on OVHcloud.

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

## Scripts included

| Script | Purpose |
|---|---|
| [`provision.sh`](./provision.sh) | Full workflow — site + database + Git + SSL + deploy |
| [`git-setup.sh`](./git-setup.sh) | Git only — init, create remote repo, push, link to Forge |
| [`ssl.sh`](./ssl.sh) | SSL only — Let's Encrypt on an existing Forge site |

---

## Usage

### Full provisioning (from local folder)

The script detects the project type automatically (Laravel, Symfony, WordPress, Next.js, Nuxt.js, Node.js, static HTML) and generates an appropriate deployment script.

```bash
bash ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/provision.sh \
  --domain monsite.com \
  --local-path /path/to/project \
  --server-id 12345
```

### Full provisioning (existing Git repo)

```bash
bash ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/provision.sh \
  --domain monsite.com \
  --repo username/repo-name \
  --branch main \
  --server-id 12345
```

### With database

```bash
bash ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/provision.sh \
  --domain monsite.com \
  --local-path /path/to/project \
  --server-id 12345 \
  --db monsite_db \
  --db-user monsite_user \
  --db-pass secret
```

### Git setup only (site already exists on Forge)

```bash
cd /my/project
bash ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/git-setup.sh \
  --site monsite.com
```

### SSL only (site already created)

```bash
bash ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/ssl.sh \
  --site monsite.com
```

---

## Automatic project type detection

| Detected signal | Forge type | Deployment generated |
|---|---|---|
| `artisan` | `php` | `git pull` + composer + artisan migrate + cache + FPM reload |
| `symfony.lock` / `bin/console` | `php` | composer + doctrine migrate + cache:clear + FPM reload |
| `wp-login.php` | `php` | composer + FPM reload |
| `next.config.*` | `html` | npm ci + build + pm2 |
| `nuxt.config.*` | `html` | npm ci + build + pm2 |
| `package.json` | `html` | npm ci + pm2 |
| `index.html` | `html` | git pull only |
| `composer.json` | `php` | composer + FPM reload |

Override with `--type laravel` (or `symfony`, `nextjs`, `static`, etc.).

---

## Full provisioning workflow

```
1. Create Forge site (API)
2. Create database (optional)
3. Set up Git
   ├─ --repo provided  → link directly to Forge
   └─ --local-path     → git init + create remote (GitHub/GitLab) + push + link
4. Configure deployment script (adapted to project type)
5. SSL — Let's Encrypt (mandatory)
6. First deployment
```

---

## Validation checklist

```
- [ ] forge site:list shows the new site
- [ ] GitHub/GitLab repo exists and is linked
- [ ] git push → auto-deploy triggered
- [ ] curl -sI http://monsite.com  → 301 to HTTPS
- [ ] curl -sI https://monsite.com → HTTP/2 200
- [ ] forge deploy:logs — success
```

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
