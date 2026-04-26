---
name: forge-api-provision
description: Create and provision Forge resources via the REST API — sites, databases, SSL/Let's Encrypt certificates, Git project installation, domain configuration. Use when the user wants to create a site, create a database, configure SSL, install a Git repo, or automate provisioning tasks that go beyond the Forge CLI.
---

# Forge API — Provisioning Resources

Base URL: `https://forge.laravel.com/api/v1`

## Authentication

```bash
# All requests need:
Authorization: Bearer $FORGE_API_TOKEN
Accept: application/json
Content-Type: application/json
```

Set `FORGE_API_TOKEN` in your environment or CI secrets.

## Get Server & Site IDs

Before provisioning, retrieve IDs:

```bash
# List servers
curl -s -H "Authorization: Bearer $FORGE_API_TOKEN" \
     -H "Accept: application/json" \
     https://forge.laravel.com/api/v1/servers | jq '.servers[] | {id, name}'

# List sites on server
curl -s -H "Authorization: Bearer $FORGE_API_TOKEN" \
     -H "Accept: application/json" \
     https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites | jq '.sites[] | {id, name}'
```

## Create a Site

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites \
  -d '{
    "domain": "monsite.com",
    "project_type": "php",
    "directory": "/public",
    "php_version": "php83",
    "isolated": false
  }'
```

**project_type**: `php` (Laravel/Symfony) ou `html` (statique/Next.js)

> Poll `GET /api/v1/servers/{serverId}/sites/{siteId}` until `status == "installed"`.

## Install Git Repository

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/git \
  -d '{
    "provider": "github",
    "repository": "username/repo-name",
    "branch": "main",
    "composer": true
  }'
```

**provider**: `github`, `gitlab`, `gitlab-custom`, `bitbucket`, `custom`

## Create a Database

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/databases \
  -d '{
    "name": "monsite_db",
    "user": "monsite_user",
    "password": "secret_password"
  }'
```

> `user` and `password` are optional. If omitted, only the DB is created without a new user.

## SSL — Let's Encrypt (obligatoire sur tous les sites)

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/certificates/letsencrypt \
  -d '{
    "domains": ["monsite.com", "www.monsite.com"]
  }'
```

Poll until `active == true`:
```bash
curl -s -H "Authorization: Bearer $FORGE_API_TOKEN" \
     -H "Accept: application/json" \
     https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/certificates/$CERT_ID
```

## Update .env File

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/env \
  -d "{\"content\": $(cat .env.production | jq -Rs .)}"
```

## Deploy Now

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/deployment/deploy
```

## Update Deployment Script

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/deployment/script \
  -d '{
    "content": "cd /home/forge/monsite.com\ngit pull origin main\ncomposer install --no-interaction --prefer-dist --optimize-autoloader\nphp artisan migrate --force\nphp artisan config:cache\nphp artisan route:cache\nphp artisan view:cache\n( flock -w 10 9 || exit 1\necho '\''Restarting FPM...'\''; sudo -S service php8.3-fpm reload ) 9>/tmp/fpmlock",
    "auto_source": true
  }'
```

## Enable Quick Deploy (auto-deploy on push)

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/deployment
```

## Reference

For complete API documentation: [forge.laravel.com/api-documentation](https://forge.laravel.com/api-documentation)
