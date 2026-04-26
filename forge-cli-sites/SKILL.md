---
name: forge-cli-sites
description: Manage Laravel Forge sites via CLI — list sites, deploy, manage environment variables, view logs, run commands, use Tinker. Use when the user asks about forge deploy, env:pull, env:push, site:logs, forge command, forge tinker, or deploy:logs.
---

# Forge CLI — Sites & Deployments

## List Sites

```bash
forge site:list   # List all sites on active server
```

## Deploy

```bash
forge deploy               # Deploy default site (from current dir)
forge deploy example.com   # Deploy specific site
```

Monitor deployment: `forge deploy:logs`

## Deployment Logs

```bash
forge deploy:logs          # Latest deployment output
forge deploy:logs 12345    # Specific deployment ID
```

## Environment Variables

```bash
# Pull .env from server to local
forge env:pull
forge env:pull example.com
forge env:pull example.com .env.production

# Edit the file locally, then push back
forge env:push
forge env:push example.com
forge env:push example.com .env.production
```

> After pushing env vars, redeploy if using config cache or queue workers.

## Application Logs

```bash
forge site:logs                        # Current site
forge site:logs --follow               # Realtime
forge site:logs example.com
forge site:logs example.com --follow
```

## Run Remote Commands

```bash
forge command                                          # Interactive
forge command example.com
forge command example.com --command="php artisan migrate"
forge command example.com --command="php artisan queue:restart"
```

Commands run relative to the site's root directory.

## Tinker (Laravel only)

```bash
forge tinker
forge tinker example.com
```

## Open in Forge Dashboard

```bash
forge open example.com   # Opens site in forge.laravel.com
```

## Common Deployment Workflow

```bash
# 1. Switch to correct server
forge server:switch production

# 2. Push updated env vars if needed
forge env:push example.com .env.production

# 3. Deploy
forge deploy example.com

# 4. Watch logs
forge deploy:logs

# 5. Verify app health
forge command example.com --command="php artisan about"
```
