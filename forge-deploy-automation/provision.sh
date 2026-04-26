#!/usr/bin/env bash
# provision.sh — Automatise la création complète d'un site sur Laravel Forge
#
# Usage avec dépôt GitHub/GitLab existant :
#   bash provision.sh --domain monsite.com --repo user/repo --server-id 12345
#
# Usage depuis un dossier local (crée le dépôt si nécessaire) :
#   bash provision.sh --domain monsite.com --local-path /path/to/project --server-id 12345
#
# Le type de projet est détecté automatiquement.
# JAMAIS de rsync — le déploiement passe toujours par Git.

set -euo pipefail

# ─── Couleurs ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step()    { echo -e "\n${BLUE}▶ $*${NC}"; }

# ─── Paramètres ──────────────────────────────────────────────────────────────
DOMAIN="" REPO="" BRANCH="main" DB="" DB_USER="" DB_PASS=""
SERVER_ID="" PHP_VERSION="php83"
FORGE_API_TOKEN="${FORGE_API_TOKEN:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GIT_PROVIDER="${GIT_PROVIDER:-github}"
PROJECT_TYPE=""       # vide = auto-détection
LOCAL_PATH=""         # dossier local source (si pas de --repo)
GIT_VISIBILITY="private"

while [[ $# -gt 0 ]]; do
  case $1 in
    --domain)        DOMAIN="$2";           shift 2 ;;
    --repo)          REPO="$2";             shift 2 ;;
    --local-path)    LOCAL_PATH="$2";       shift 2 ;;
    --branch)        BRANCH="$2";           shift 2 ;;
    --db)            DB="$2";               shift 2 ;;
    --db-user)       DB_USER="$2";          shift 2 ;;
    --db-pass)       DB_PASS="$2";          shift 2 ;;
    --server-id)     SERVER_ID="$2";        shift 2 ;;
    --php)           PHP_VERSION="$2";      shift 2 ;;
    --token)         FORGE_API_TOKEN="$2";  shift 2 ;;
    --github-token)  GITHUB_TOKEN="$2";     shift 2 ;;
    --provider)      GIT_PROVIDER="$2";     shift 2 ;;
    --type)          PROJECT_TYPE="$2";     shift 2 ;;
    --public)        GIT_VISIBILITY="public"; shift ;;
    *) error "Option inconnue: $1" ;;
  esac
done

# ─── Validation ──────────────────────────────────────────────────────────────
if [[ -z "$FORGE_API_TOKEN" ]] && [[ -f "$HOME/.laravel-forge/config.json" ]]; then
  FORGE_API_TOKEN=$(python3 -c "import json; print(json.load(open('$HOME/.laravel-forge/config.json'))['token'])")
fi
[[ -z "$FORGE_API_TOKEN" ]] && error "FORGE_API_TOKEN non défini"
[[ -z "$DOMAIN" ]]    && error "--domain requis"
[[ -z "$SERVER_ID" ]] && error "--server-id requis"
[[ -z "$REPO" && -z "$LOCAL_PATH" ]] && error "--repo ou --local-path requis"

API="https://forge.laravel.com/api/v1"
HEADERS=(-H "Authorization: Bearer $FORGE_API_TOKEN" -H "Accept: application/json" -H "Content-Type: application/json")

forge_get()  { curl -sf "${HEADERS[@]}" "$API/$1"; }
forge_post() { curl -sf -X POST "${HEADERS[@]}" "$API/$1" -d "$2"; }
forge_put()  { curl -sf -X PUT  "${HEADERS[@]}" "$API/$1" -d "$2"; }

# Vérifie si un fichier existe dans le repo GitHub (retourne 0 si trouvé)
github_file_exists() {
  local file="$1"
  local gh_headers=(-H "Accept: application/vnd.github.v3+json")
  [[ -n "$GITHUB_TOKEN" ]] && gh_headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" "${gh_headers[@]}" \
    "https://api.github.com/repos/$REPO/contents/$file?ref=$BRANCH")
  [[ "$http_code" == "200" ]]
}

# ─── Détection automatique du type de projet ─────────────────────────────────

# Détection depuis un dossier local (mode --local-path)
detect_project_type_local() {
  local dir="$1"
  step "Détection du type de projet (dossier local : $dir)..."

  if [[ -f "$dir/artisan" ]]; then
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="laravel"
    info "Détecté : Laravel"
  elif [[ -f "$dir/symfony.lock" || -f "$dir/bin/console" ]]; then
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="symfony"
    info "Détecté : Symfony"
  elif [[ -f "$dir/wp-login.php" || -f "$dir/wp-config-sample.php" ]]; then
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="wordpress"
    info "Détecté : WordPress"
  elif [[ -f "$dir/next.config.js" || -f "$dir/next.config.ts" || -f "$dir/next.config.mjs" ]]; then
    PROJECT_TYPE="html"; DEPLOY_FLAVOR="nextjs"
    info "Détecté : Next.js"
  elif [[ -f "$dir/nuxt.config.js" || -f "$dir/nuxt.config.ts" ]]; then
    PROJECT_TYPE="html"; DEPLOY_FLAVOR="nuxtjs"
    info "Détecté : Nuxt.js"
  elif [[ -f "$dir/package.json" ]]; then
    PROJECT_TYPE="html"; DEPLOY_FLAVOR="nodejs"
    info "Détecté : Node.js / SPA"
  elif [[ -f "$dir/composer.json" ]]; then
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="php-generic"
    info "Détecté : PHP générique"
  elif [[ -f "$dir/index.html" ]]; then
    PROJECT_TYPE="html"; DEPLOY_FLAVOR="static"
    info "Détecté : HTML statique"
  else
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="php-generic"
    warn "Type non détecté — défaut : PHP générique"
  fi
}

# Détection depuis l'API GitHub (mode --repo)
detect_project_type() {
  step "Détection du type de projet ($REPO @ $BRANCH)..."

  if github_file_exists "artisan"; then
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="laravel"
    info "Détecté : Laravel"
  elif github_file_exists "symfony.lock" || github_file_exists "bin/console"; then
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="symfony"
    info "Détecté : Symfony"
  elif github_file_exists "wp-login.php" || github_file_exists "wp-config-sample.php"; then
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="wordpress"
    info "Détecté : WordPress"
  elif github_file_exists "next.config.js" || github_file_exists "next.config.ts" || github_file_exists "next.config.mjs"; then
    PROJECT_TYPE="html"; DEPLOY_FLAVOR="nextjs"
    info "Détecté : Next.js"
  elif github_file_exists "nuxt.config.js" || github_file_exists "nuxt.config.ts"; then
    PROJECT_TYPE="html"; DEPLOY_FLAVOR="nuxtjs"
    info "Détecté : Nuxt.js"
  elif github_file_exists "package.json"; then
    PROJECT_TYPE="html"; DEPLOY_FLAVOR="nodejs"
    info "Détecté : Node.js / SPA"
  elif github_file_exists "composer.json"; then
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="php-generic"
    info "Détecté : PHP générique"
  elif github_file_exists "index.html"; then
    PROJECT_TYPE="html"; DEPLOY_FLAVOR="static"
    info "Détecté : HTML statique"
  else
    PROJECT_TYPE="php"; DEPLOY_FLAVOR="php-generic"
    warn "Type non détecté — défaut : PHP générique"
  fi
}

# ─── Construction du script de déploiement selon le type ─────────────────────
build_deploy_script() {
  local flavor="$1"
  case "$flavor" in
    laravel)
      cat <<SCRIPT
cd /home/forge/$DOMAIN
git pull origin $BRANCH
\$FORGE_COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader
\$FORGE_PHP artisan migrate --force
\$FORGE_PHP artisan config:cache
\$FORGE_PHP artisan route:cache
\$FORGE_PHP artisan view:cache
\$FORGE_PHP artisan queue:restart
( flock -w 10 9 || exit 1
    echo 'Restarting FPM...'; sudo -S service $PHP_VERSION-fpm reload ) 9>/tmp/fpmlock
SCRIPT
      ;;

    symfony)
      cat <<SCRIPT
cd /home/forge/$DOMAIN
git pull origin $BRANCH
\$FORGE_COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader
\$FORGE_PHP bin/console doctrine:migrations:migrate --no-interaction
\$FORGE_PHP bin/console cache:clear
( flock -w 10 9 || exit 1
    echo 'Restarting FPM...'; sudo -S service $PHP_VERSION-fpm reload ) 9>/tmp/fpmlock
SCRIPT
      ;;

    wordpress)
      cat <<SCRIPT
cd /home/forge/$DOMAIN
git pull origin $BRANCH
\$FORGE_COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader
( flock -w 10 9 || exit 1
    echo 'Restarting FPM...'; sudo -S service $PHP_VERSION-fpm reload ) 9>/tmp/fpmlock
SCRIPT
      ;;

    nextjs)
      cat <<SCRIPT
cd /home/forge/$DOMAIN
git pull origin $BRANCH
npm ci
npm run build
pm2 restart all || pm2 start npm --name "$DOMAIN" -- start
SCRIPT
      ;;

    nuxtjs)
      cat <<SCRIPT
cd /home/forge/$DOMAIN
git pull origin $BRANCH
npm ci
npm run build
pm2 restart all || pm2 start npm --name "$DOMAIN" -- start
SCRIPT
      ;;

    nodejs)
      cat <<SCRIPT
cd /home/forge/$DOMAIN
git pull origin $BRANCH
npm ci
npm run build 2>/dev/null || true
pm2 restart all || pm2 start ecosystem.config.js 2>/dev/null || pm2 start index.js --name "$DOMAIN"
SCRIPT
      ;;

    static)
      cat <<SCRIPT
cd /home/forge/$DOMAIN
git pull origin $BRANCH
SCRIPT
      ;;

    php-generic|*)
      cat <<SCRIPT
cd /home/forge/$DOMAIN
git pull origin $BRANCH
\$FORGE_COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader
( flock -w 10 9 || exit 1
    echo 'Restarting FPM...'; sudo -S service $PHP_VERSION-fpm reload ) 9>/tmp/fpmlock
SCRIPT
      ;;
  esac
}

wait_for() {
  local url="$1" field="$2" value="$3" label="$4"
  info "Attente : $label..."
  for i in $(seq 1 30); do
    local result
    result=$(forge_get "$url" | jq -r ".$field // empty" 2>/dev/null || true)
    [[ "$result" == "$value" ]] && return 0
    echo -n "."
    sleep 10
  done
  echo ""
  error "Timeout : $label n'a pas atteint '$value' en 5 minutes"
}

# ─── Détection du type de projet ─────────────────────────────────────────────
if [[ -n "$PROJECT_TYPE" ]]; then
  # Type forcé manuellement via --type
  DEPLOY_FLAVOR="$PROJECT_TYPE"
  warn "Type forcé manuellement : $PROJECT_TYPE"
elif [[ -n "$LOCAL_PATH" ]]; then
  # Mode dossier local : inspection directe des fichiers
  detect_project_type_local "$LOCAL_PATH"
elif [[ "$GIT_PROVIDER" == "github" && -n "$REPO" ]]; then
  # Mode repo GitHub existant : interroger l'API GitHub
  detect_project_type
else
  warn "Détection automatique non disponible (provider: $GIT_PROVIDER). Défaut : php/laravel."
  PROJECT_TYPE="php"
  DEPLOY_FLAVOR="laravel"
fi

# Résumé avant provisioning
echo ""
echo -e "${BLUE}┌─ Configuration ──────────────────────────────┐${NC}"
echo -e "${BLUE}│${NC} Domaine      : $DOMAIN"
echo -e "${BLUE}│${NC} Source       : ${REPO:-$LOCAL_PATH} ($BRANCH)"
echo -e "${BLUE}│${NC} Type Forge   : $PROJECT_TYPE"
echo -e "${BLUE}│${NC} Flavor       : $DEPLOY_FLAVOR"
[[ -n "$DB" ]] && echo -e "${BLUE}│${NC} Base de données : $DB"
echo -e "${BLUE}│${NC} PHP          : $PHP_VERSION"
echo -e "${BLUE}└──────────────────────────────────────────────┘${NC}"
echo ""

# ─── 1. Créer le site ────────────────────────────────────────────────────────
step "1/6 Création du site $DOMAIN..."

# Le web_directory diffère selon le type
WEB_DIR="/public"
[[ "$DEPLOY_FLAVOR" == "static" || "$DEPLOY_FLAVOR" == "nodejs" ]] && WEB_DIR="/"
[[ "$DEPLOY_FLAVOR" == "nextjs" || "$DEPLOY_FLAVOR" == "nuxtjs" ]] && WEB_DIR="/"

SITE_PAYLOAD=$(jq -n \
  --arg domain "$DOMAIN" \
  --arg type "$PROJECT_TYPE" \
  --arg php "$PHP_VERSION" \
  --arg dir "$WEB_DIR" \
  '{domain: $domain, project_type: $type, php_version: $php, directory: $dir}')

SITE=$(forge_post "servers/$SERVER_ID/sites" "$SITE_PAYLOAD")
SITE_ID=$(echo "$SITE" | jq -r '.site.id')
[[ -z "$SITE_ID" || "$SITE_ID" == "null" ]] && error "Échec de la création du site. Réponse: $SITE"
info "Site créé (ID: $SITE_ID)"

wait_for "servers/$SERVER_ID/sites/$SITE_ID" "site.status" "installed" "installation du site"
echo ""

# ─── 2. Créer la base de données ─────────────────────────────────────────────
if [[ -n "$DB" ]]; then
  step "2/6 Création de la base de données $DB..."
  DB_PAYLOAD=$(jq -n --arg name "$DB" --arg user "$DB_USER" --arg pass "$DB_PASS" \
    '{name: $name, user: $user, password: $pass}')
  DB_RESULT=$(forge_post "servers/$SERVER_ID/databases" "$DB_PAYLOAD")
  DB_ID=$(echo "$DB_RESULT" | jq -r '.database.id')
  info "Base de données créée (ID: $DB_ID)"
else
  info "2/6 Pas de base de données demandée (ignoré)"
fi

# ─── 3. Préparer le dépôt Git ────────────────────────────────────────────────
step "3/6 Préparation du dépôt Git..."

SKILL_DIR="$(dirname "${BASH_SOURCE[0]}")"

if [[ -n "$LOCAL_PATH" ]]; then
  # Mode local : git-setup.sh s'occupe de tout (init, création repo distant, push)
  info "Dossier local détecté : $LOCAL_PATH"
  bash "$SKILL_DIR/git-setup.sh" \
    --path "$LOCAL_PATH" \
    --site "$DOMAIN" \
    --server-id "$SERVER_ID" \
    --site-id "$SITE_ID" \
    --provider "$GIT_PROVIDER" \
    --visibility "$GIT_VISIBILITY" \
    --branch "$BRANCH"

  # Récupérer le slug repo depuis le remote configuré par git-setup.sh
  REPO=$(git -C "$LOCAL_PATH" remote get-url origin \
    | sed -E 's|.*[:/]([^/]+/[^/]+?)(\.git)?$|\1|')
  info "Dépôt lié : $REPO"

else
  # Mode repo existant : lier directement
  INSTALL_COMPOSER=true
  [[ "$DEPLOY_FLAVOR" == "static" || "$DEPLOY_FLAVOR" == "nextjs" || \
     "$DEPLOY_FLAVOR" == "nuxtjs" || "$DEPLOY_FLAVOR" == "nodejs" ]] && INSTALL_COMPOSER=false

  GIT_PAYLOAD=$(jq -n \
    --arg repo "$REPO" \
    --arg branch "$BRANCH" \
    --arg db "$DB" \
    --arg provider "$GIT_PROVIDER" \
    --argjson composer "$INSTALL_COMPOSER" \
    '{provider: $provider, repository: $repo, branch: $branch, composer: $composer, database: $db}')
  forge_post "servers/$SERVER_ID/sites/$SITE_ID/git" "$GIT_PAYLOAD" > /dev/null

  wait_for "servers/$SERVER_ID/sites/$SITE_ID" "site.repository_status" "installed" "installation Git"
  echo ""
  info "Dépôt Git installé"
fi

# ─── 4. Mettre à jour le script de déploiement ───────────────────────────────
step "4/6 Configuration du script de déploiement ($DEPLOY_FLAVOR)..."
DEPLOY_SCRIPT=$(build_deploy_script "$DEPLOY_FLAVOR")
DEPLOY_PAYLOAD=$(jq -n --arg content "$DEPLOY_SCRIPT" '{content: $content, auto_source: true}')
forge_put "servers/$SERVER_ID/sites/$SITE_ID/deployment/script" "$DEPLOY_PAYLOAD" > /dev/null
info "Script de déploiement mis à jour"

# ─── 5. Certificat Let's Encrypt ─────────────────────────────────────────────
step "5/6 Certificat SSL Let's Encrypt pour $DOMAIN..."
SSL_PAYLOAD=$(jq -n --arg d "$DOMAIN" --arg www "www.$DOMAIN" '{domains: [$d, $www]}')
SSL_RESULT=$(forge_post "servers/$SERVER_ID/sites/$SITE_ID/certificates/letsencrypt" "$SSL_PAYLOAD")
CERT_ID=$(echo "$SSL_RESULT" | jq -r '.certificate.id')
info "Certificat en cours d'installation (ID: $CERT_ID)..."

wait_for "servers/$SERVER_ID/sites/$SITE_ID/certificates/$CERT_ID" "certificate.active" "true" "activation SSL"
echo ""
info "SSL actif"

# ─── 6. Premier déploiement ──────────────────────────────────────────────────
step "6/6 Premier déploiement..."
forge_post "servers/$SERVER_ID/sites/$SITE_ID/deployment/deploy" "{}" > /dev/null

echo ""
echo -e "${GREEN}✓ Provisioning terminé pour https://$DOMAIN${NC}"
echo ""
echo "  Suivi du déploiement :"
echo "    forge deploy:logs"
echo "    forge site:logs $DOMAIN --follow"
echo ""
echo "  Informations :"
echo "    Site ID  : $SITE_ID"
echo "    Cert ID  : ${CERT_ID:-n/a}"
echo "    Flavor   : $DEPLOY_FLAVOR"
