# forge-api-provision

Agent skill — Provision Laravel Forge resources via REST API: create sites, databases, link Git repositories, issue SSL certificates, update deployment scripts.

Triggers automatically when you ask to create a Forge site, set up a database, configure SSL, install a Git repo, or automate anything beyond what the Forge CLI supports.

> The Forge CLI only manages existing resources. **Creating** sites, databases, SSL certificates, and Git links requires the Forge API — this skill handles that.

---

## Prerequisites

### Forge API Token

Generate at: [forge.laravel.com/profile/api](https://forge.laravel.com/profile/api)

```bash
# Set in your environment
export FORGE_API_TOKEN=your-token-here

# Or it is read automatically from ~/.laravel-forge/config.json
# if you have authenticated via the Forge CLI
forge login --token=your-token-here
```

### jq

```bash
brew install jq
```

### curl

Pre-installed on macOS and most Linux distributions.

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

## What this skill covers

| Operation | API endpoint |
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

## Quick reference

```bash
# Get your server ID
curl -s -H "Authorization: Bearer $FORGE_API_TOKEN" \
     -H "Accept: application/json" \
     https://forge.laravel.com/api/v1/servers | jq '.servers[] | {id, name}'

# Create a site
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites \
  -d '{"domain": "monsite.com", "project_type": "php", "directory": "/public", "php_version": "php83"}'

# Trigger a deployment
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/deployment/deploy
```

**project_type**: `php` (Laravel, Symfony, WordPress) or `html` (static, Next.js, Nuxt.js, Node.js)

---

## SSL is mandatory

Every site must have a Let's Encrypt certificate. The API call:

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/certificates/letsencrypt \
  -d '{"domains": ["monsite.com", "www.monsite.com"]}'
```

DNS must be propagated before requesting the certificate.

---

## API reference

Full documentation: [forge.laravel.com/api-documentation](https://forge.laravel.com/api-documentation)

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
