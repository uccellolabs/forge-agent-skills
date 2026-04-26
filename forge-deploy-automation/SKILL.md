---
name: forge-deploy-automation
description: Automate the complete Laravel Forge site provisioning workflow — create site, create database, setup Git (GitHub/GitLab), configure .env, enable SSL/Let's Encrypt, and deploy. NEVER uses rsync — always deploys via Git. Use when the user wants to deploy a site to Forge, set up CI/CD, link a Git repo to Forge, create a GitHub/GitLab repo for an existing project, or automate the full site lifecycle.
---

# Forge Deploy Automation — Workflow Complet

**Règle absolue : jamais de rsync. Tout déploiement passe par Git.**

## Scripts disponibles

| Script | Rôle |
|---|---|
| [provision.sh](provision.sh) | Workflow complet : site + BDD + Git + SSL + déploiement |
| [git-setup.sh](git-setup.sh) | Git seul : init, création repo GitHub/GitLab, liaison Forge |
| [ssl.sh](ssl.sh) | SSL seul : Let's Encrypt sur un site existant |

## Logique Git — 2 cas

### Cas 1 — Dépôt Git déjà configuré (`--repo`)

```bash
bash provision.sh \
  --domain monsite.com \
  --repo username/monsite \
  --branch main \
  --server-id 12345
```

Le dépôt GitHub/GitLab est lié directement à Forge.

### Cas 2 — Dossier local sans Git (`--local-path`)

```bash
bash provision.sh \
  --domain monsite.com \
  --local-path /path/to/project \
  --server-id 12345
```

Le script automatiquement :
1. Détecte si Git est initialisé dans le dossier
2. Si non → `git init`
3. Détecte si un remote existe → sinon, **demande GitHub ou GitLab**
4. Crée le dépôt distant (GitHub via `gh` CLI, GitLab via API)
5. Commit + push du code
6. Lie le dépôt au site Forge
7. Active le quick deploy (auto-deploy sur `git push`)

### Utiliser git-setup.sh seul (site déjà créé sur Forge)

```bash
# Depuis le dossier du projet
cd /mon/projet
bash ~/.cursor/skills/forge-deploy-automation/git-setup.sh \
  --site monsite.com

# Ou en spécifiant tout
bash ~/.cursor/skills/forge-deploy-automation/git-setup.sh \
  --path /mon/projet \
  --site monsite.com \
  --provider github \
  --visibility private
```

## Prérequis

- `FORGE_API_TOKEN` défini ou `~/.laravel-forge/config.json` présent
- `gh` CLI installé et authentifié pour GitHub (`brew install gh && gh auth login`)
- `glab` CLI installé et authentifié pour GitLab (`brew install glab && glab auth login`)
- `jq` installé (`brew install jq`)
- DNS du domaine pointant vers l'IP du serveur avant le SSL

## Détection automatique du type de projet

Avant de créer le site, le script interroge l'API GitHub pour détecter :

| Signal dans le repo | Type Forge | Flavor | Déploiement généré |
|---|---|---|---|
| `artisan` | `php` | `laravel` | migrate, cache, fpm reload |
| `symfony.lock` ou `bin/console` | `php` | `symfony` | doctrine migrate, cache:clear |
| `wp-login.php` | `php` | `wordpress` | composer, fpm reload |
| `composer.json` seul | `php` | `php-generic` | composer, fpm reload |
| `next.config.*` | `html` | `nextjs` | npm ci, build, pm2 |
| `nuxt.config.*` | `html` | `nuxtjs` | npm ci, build, pm2 |
| `package.json` seul | `html` | `nodejs` | npm ci, pm2 |
| `index.html` seul | `html` | `static` | git pull uniquement |

## Workflow complet

```
1. Créer le site Forge (API)
      ↓
2. Créer la BDD (optionnel)
      ↓
3. Préparer Git
   ├─ --repo fourni     → lier directement à Forge
   └─ --local-path      → git init + créer repo GitHub/GitLab + push + lier
      ↓
4. Configurer le script de déploiement (selon flavor détectée)
      ↓
5. ⚡ SSL Let's Encrypt (OBLIGATOIRE — HTTP → HTTPS automatique)
      ↓
6. Premier déploiement
```

## SSL — Toujours obligatoire

Le SSL est activé sur chaque site, sans exception. Forge gère le renouvellement automatique.

```bash
# Sur un site existant
bash ~/.cursor/skills/forge-deploy-automation/ssl.sh --site monsite.com
```

## Checklist de validation

```
- [ ] forge site:list montre le nouveau site
- [ ] gh repo view username/repo (ou GitLab) — dépôt créé et public/privé
- [ ] git push → déploiement automatique déclenché
- [ ] curl -sI http://monsite.com  → 301 HTTPS
- [ ] curl -sI https://monsite.com → HTTP/2 200
- [ ] forge deploy:logs — succès
```

## Dépannage SSL

| Problème | Cause | Solution |
|---|---|---|
| Échec Let's Encrypt | DNS pas propagé | Attendre + relancer ssl.sh |
| HTTP ne redirige pas | Nginx non rechargé | `forge nginx:restart` |
| Repo non lié | Site créé sans Git | Lancer git-setup.sh séparément |

## Ressources complémentaires

- Setup CLI : voir skill `forge-cli-setup`
- Gestion serveurs : voir skill `forge-cli-servers`
- Déploiements quotidiens : voir skill `forge-cli-sites`
- Détails API : voir skill `forge-api-provision`
- DNS OVH : voir skill `ovh-dns-forge`
