# forge-api-provision

Agent skill — Provision Laravel Forge resources via REST API: create sites, databases, link Git repositories, issue SSL certificates, update deployment scripts.

> The Forge CLI only manages existing resources. **Creating** sites, databases, SSL certificates, and Git links requires the Forge API — this skill covers that.

---

## What you can say to the agent

```
"Crée un nouveau site monsite.com sur mon serveur Forge"
"Ajoute une base de données MySQL monsite_db sur le serveur"
"Lie le dépôt GitHub username/repo à ce site Forge"
"Active le SSL Let's Encrypt sur example.com"
"Met à jour le script de déploiement pour example.com"
"Active l'auto-deploy sur git push pour ce site"
"Déclenche un déploiement manuel sur example.com"
"Pousse le fichier .env.production sur le serveur"
```

---

## Installation

### Cursor

```bash
ln -s ~/.cursor/skills/forge-agent-skills/forge-api-provision \
      ~/.cursor/skills/forge-api-provision

# Or install all skills
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

### Claude Desktop

1. Open a Claude Project → **Add content**
2. Paste the content of [`SKILL.md`](./SKILL.md)

### Claude Code

```markdown
## Forge API Provisioning
~/.cursor/skills/forge-agent-skills/forge-api-provision/SKILL.md
```

---

## Prerequisites

### Forge API Token

```bash
# Set in environment
export FORGE_API_TOKEN=your-token-here

# Or authenticate via CLI (token stored in ~/.laravel-forge/config.json)
forge login --token=your-token-here
```

Generate at: [forge.laravel.com/profile/api](https://forge.laravel.com/profile/api)

### jq

```bash
brew install jq
```

---

## API operations covered

| Operation | Endpoint |
|---|---|
| List servers | `GET /servers` |
| Create site | `POST /servers/{id}/sites` |
| Link Git repo | `POST /servers/{id}/sites/{id}/git` |
| Create database | `POST /servers/{id}/databases` |
| Issue SSL (Let's Encrypt) | `POST /servers/{id}/sites/{id}/certificates/letsencrypt` |
| Update `.env` | `PUT /servers/{id}/sites/{id}/env` |
| Update deploy script | `PUT /servers/{id}/sites/{id}/deployment/script` |
| Enable quick deploy | `POST /servers/{id}/sites/{id}/deployment` |
| Trigger deploy | `POST /servers/{id}/sites/{id}/deployment/deploy` |

---

## Manual reference

```bash
# Get server ID
curl -s -H "Authorization: Bearer $FORGE_API_TOKEN" \
     -H "Accept: application/json" \
     https://forge.laravel.com/api/v1/servers | jq '.servers[] | {id, name}'

# Create site
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites \
  -d '{"domain":"monsite.com","project_type":"php","directory":"/public","php_version":"php83"}'

# Issue SSL certificate
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/certificates/letsencrypt \
  -d '{"domains":["monsite.com","www.monsite.com"]}'

# Trigger deploy
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/deployment/deploy
```

**project_type**: `php` (Laravel, Symfony, WordPress) or `html` (static, Next.js, Nuxt.js, Node.js)

Full API docs: [forge.laravel.com/api-documentation](https://forge.laravel.com/api-documentation)

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
