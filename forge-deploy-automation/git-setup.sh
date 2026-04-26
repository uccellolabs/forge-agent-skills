#!/usr/bin/env bash
# git-setup.sh — Prépare un dépôt Git local et le publie sur GitHub ou GitLab
#                Puis lie le dépôt au site Forge correspondant.
#
# Usage:
#   bash git-setup.sh --path /path/to/project --site monsite.com
#   bash git-setup.sh --path /path/to/project --server-id 1234 --site-id 5678
#
# Variables optionnelles:
#   FORGE_API_TOKEN  (ou ~/.laravel-forge/config.json)
#   GITHUB_TOKEN     (ou `gh auth login` préalable)
#   GIT_PROVIDER     github|gitlab  (défaut: github)
#   GIT_VISIBILITY   public|private (défaut: private)

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step()    { echo -e "\n${BLUE}▶ $*${NC}"; }
ask()     { echo -e "${YELLOW}?${NC} $*"; }

# ─── Paramètres ──────────────────────────────────────────────────────────────
LOCAL_PATH="${PWD}"
SITE_DOMAIN="" SERVER_ID="" SITE_ID=""
GIT_PROVIDER="${GIT_PROVIDER:-}"      # vide = auto-détection ou prompt
GIT_VISIBILITY="${GIT_VISIBILITY:-private}"
BRANCH="main"
REPO_NAME=""                          # vide = déduit du domaine ou du dossier
FORGE_API_TOKEN="${FORGE_API_TOKEN:-}"
SKIP_FORGE_LINK=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)         LOCAL_PATH="$2";    shift 2 ;;
    --site)         SITE_DOMAIN="$2";   shift 2 ;;
    --server-id)    SERVER_ID="$2";     shift 2 ;;
    --site-id)      SITE_ID="$2";       shift 2 ;;
    --provider)     GIT_PROVIDER="$2";  shift 2 ;;
    --visibility)   GIT_VISIBILITY="$2"; shift 2 ;;
    --branch)       BRANCH="$2";        shift 2 ;;
    --repo-name)    REPO_NAME="$2";     shift 2 ;;
    --no-forge)     SKIP_FORGE_LINK=true; shift ;;
    *) error "Option inconnue: $1" ;;
  esac
done

[[ -d "$LOCAL_PATH" ]] || error "Chemin introuvable: $LOCAL_PATH"
cd "$LOCAL_PATH"

# ─── Auth Forge ──────────────────────────────────────────────────────────────
if [[ -z "$FORGE_API_TOKEN" ]] && [[ -f "$HOME/.laravel-forge/config.json" ]]; then
  FORGE_API_TOKEN=$(python3 -c "import json; print(json.load(open('$HOME/.laravel-forge/config.json'))['token'])")
fi
if [[ "$SKIP_FORGE_LINK" == "false" ]]; then
  [[ -z "$FORGE_API_TOKEN" ]] && error "FORGE_API_TOKEN non défini"
fi

API="https://forge.laravel.com/api/v1"
HFORGE=(-H "Authorization: Bearer $FORGE_API_TOKEN" -H "Accept: application/json" -H "Content-Type: application/json")
forge_get()  { curl -sf "${HFORGE[@]}" "$API/$1"; }
forge_post() { curl -sf -X POST "${HFORGE[@]}" "$API/$1" ${2:+-d "$2"}; }
forge_put()  { curl -sf -X PUT  "${HFORGE[@]}" "$API/$1" ${2:+-d "$2"}; }

# ─── Étape 1 : Détecter l'état Git local ─────────────────────────────────────
step "1. Analyse du dépôt local ($LOCAL_PATH)..."

GIT_INITIALIZED=false
GIT_HAS_REMOTE=false
REMOTE_URL=""
DETECTED_PROVIDER=""
DETECTED_REPO=""

if git rev-parse --git-dir &>/dev/null 2>&1; then
  GIT_INITIALIZED=true
  info "Dépôt Git existant détecté"

  REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
  if [[ -n "$REMOTE_URL" ]]; then
    GIT_HAS_REMOTE=true
    info "Remote origin : $REMOTE_URL"

    # Parser le provider et le slug depuis l'URL
    if echo "$REMOTE_URL" | grep -qi "github"; then
      DETECTED_PROVIDER="github"
      DETECTED_REPO=$(echo "$REMOTE_URL" \
        | sed -E 's|.*github\.com[:/]([^/]+/[^/]+?)(\.git)?$|\1|')
    elif echo "$REMOTE_URL" | grep -qi "gitlab"; then
      DETECTED_PROVIDER="gitlab"
      DETECTED_REPO=$(echo "$REMOTE_URL" \
        | sed -E 's|.*gitlab\.com[:/]([^/]+/[^/]+?)(\.git)?$|\1|')
    else
      warn "Provider non reconnu depuis l'URL: $REMOTE_URL"
    fi

    [[ -n "$DETECTED_PROVIDER" ]] && info "Détecté : $DETECTED_PROVIDER — $DETECTED_REPO"
    GIT_PROVIDER="${GIT_PROVIDER:-$DETECTED_PROVIDER}"
  fi
else
  info "Pas de dépôt Git — initialisation nécessaire"
fi

# ─── Étape 2 : Choisir le provider si non détecté ────────────────────────────
if [[ -z "$GIT_PROVIDER" ]]; then
  echo ""
  ask "Quel provider Git souhaitez-vous utiliser ?"
  echo "  1) GitHub"
  echo "  2) GitLab"
  read -r -p "  Choix [1/2]: " choice
  case "$choice" in
    2) GIT_PROVIDER="gitlab" ;;
    *) GIT_PROVIDER="github" ;;
  esac
fi

info "Provider : $GIT_PROVIDER"

# ─── Fonction : sélection du workspace ───────────────────────────────────────
# Affiche une liste numérotée et retourne le namespace choisi dans $NAMESPACE
pick_namespace() {
  local -a items=("$@")
  local count=${#items[@]}

  if [[ $count -eq 1 ]]; then
    NAMESPACE="${items[0]}"
    return
  fi

  echo ""
  ask "Dans quel workspace créer le dépôt ?"
  for i in "${!items[@]}"; do
    printf "  %2d) %s\n" "$((i+1))" "${items[$i]}"
  done
  while true; do
    read -r -p "  Choix [1-$count]: " pick
    if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= count )); then
      NAMESPACE="${items[$((pick-1))]}"
      break
    fi
    warn "Choix invalide, entrer un nombre entre 1 et $count"
  done
}

# ─── Étape 3 : Initialiser Git si nécessaire ─────────────────────────────────
if [[ "$GIT_INITIALIZED" == "false" ]]; then
  step "2. Initialisation du dépôt Git..."
  git init -b "$BRANCH"
  info "Dépôt initialisé (branche: $BRANCH)"
fi

# ─── Étape 4 : Créer le dépôt distant si nécessaire ─────────────────────────
if [[ "$GIT_HAS_REMOTE" == "false" ]]; then
  step "3. Création du dépôt distant ($GIT_PROVIDER)..."

  # Déduire le nom du dépôt
  if [[ -z "$REPO_NAME" ]]; then
    if [[ -n "$SITE_DOMAIN" ]]; then
      REPO_NAME=$(echo "$SITE_DOMAIN" | sed 's/\\./-/g')
    else
      REPO_NAME=$(basename "$LOCAL_PATH")
    fi
  fi

  case "$GIT_PROVIDER" in
    github)
      command -v gh &>/dev/null || error "GitHub CLI (gh) non installé. Installer avec: brew install gh"
      gh auth status &>/dev/null || error "Non authentifié sur GitHub. Lancer: gh auth login"

      GH_USER=$(gh api user --jq '.login')

      # Lister les orgs disponibles
      GH_ORGS=$(gh api /user/orgs --jq '.[].login' 2>/dev/null || true)

      # Construire la liste : compte perso en premier, puis orgs
      WORKSPACES=("$GH_USER (personnel)")
      while IFS= read -r org; do
        [[ -n "$org" ]] && WORKSPACES+=("$org")
      done <<< "$GH_ORGS"

      NAMESPACE=""
      pick_namespace "${WORKSPACES[@]}"

      # Extraire le login réel (enlever " (personnel)" si besoin)
      GH_OWNER=$(echo "$NAMESPACE" | sed 's/ (personnel)//')
      FULL_REPO="$GH_OWNER/$REPO_NAME"
      info "Workspace sélectionné : $GH_OWNER"

      if gh repo view "$FULL_REPO" &>/dev/null 2>&1; then
        warn "Le dépôt $FULL_REPO existe déjà sur GitHub"
        REMOTE_URL="git@github.com:$FULL_REPO.git"
      else
        info "Création du dépôt : $FULL_REPO ($GIT_VISIBILITY)"
        gh repo create "$FULL_REPO" \
          "--${GIT_VISIBILITY}" \
          --description "Déployé sur Forge — ${SITE_DOMAIN:-$REPO_NAME}"
        REMOTE_URL="git@github.com:$FULL_REPO.git"
        info "Dépôt créé : https://github.com/$FULL_REPO"
      fi

      DETECTED_REPO="$FULL_REPO"
      git remote add origin "$REMOTE_URL" 2>/dev/null || git remote set-url origin "$REMOTE_URL"
      ;;

    gitlab)
      command -v glab &>/dev/null || error "GitLab CLI (glab) non installé. Installer avec: brew install glab"
      glab auth status &>/dev/null || error "Non authentifié sur GitLab. Lancer: glab auth login"

      GL_USER=$(glab api /user 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
      GL_REPO_SLUG=$(echo "$REPO_NAME" | tr '.' '-' | tr '[:upper:]' '[:lower:]')

      # Lister tous les namespaces (compte perso + groupes)
      NAMESPACES_RAW=$(glab api /namespaces 2>/dev/null | python3 -c "
import sys, json
ns = json.load(sys.stdin)
# Perso en premier, puis groupes triés par nom
perso = [n for n in ns if n['kind'] == 'user']
groups = sorted([n for n in ns if n['kind'] == 'group'], key=lambda x: x['path'])
for n in perso + groups:
    kind = 'personnel' if n['kind'] == 'user' else 'groupe'
    print(f\"{n['path']}|{kind}\")
" 2>/dev/null || true)

      WORKSPACES=()
      while IFS='|' read -r path kind; do
        [[ -n "$path" ]] && WORKSPACES+=("$path ($kind)")
      done <<< "$NAMESPACES_RAW"

      NAMESPACE=""
      pick_namespace "${WORKSPACES[@]}"

      GL_OWNER=$(echo "$NAMESPACE" | sed -E 's/ \((personnel|groupe)\)//')
      FULL_REPO="$GL_OWNER/$GL_REPO_SLUG"
      info "Workspace sélectionné : $GL_OWNER"

      if glab repo view "$FULL_REPO" &>/dev/null 2>&1; then
        warn "Le dépôt $FULL_REPO existe déjà sur GitLab"
        REMOTE_URL="git@gitlab.com:$FULL_REPO.git"
      else
        info "Création du dépôt : $FULL_REPO ($GIT_VISIBILITY)"
        VISIBILITY_FLAG="--private"
        [[ "$GIT_VISIBILITY" == "public" ]] && VISIBILITY_FLAG="--public"
        glab repo create "$GL_OWNER/$GL_REPO_SLUG" "$VISIBILITY_FLAG" \
          --description "Déployé sur Forge — ${SITE_DOMAIN:-$REPO_NAME}" \
          --no-clone
        REMOTE_URL="git@gitlab.com:$FULL_REPO.git"
        info "Dépôt créé : https://gitlab.com/$FULL_REPO"
      fi

      DETECTED_REPO="$FULL_REPO"
      git remote add origin "$REMOTE_URL" 2>/dev/null || git remote set-url origin "$REMOTE_URL"
      ;;

    *) error "Provider non supporté: $GIT_PROVIDER" ;;
  esac
fi

# ─── Étape 5 : Commit initial et push ────────────────────────────────────────
step "4. Commit et push vers $GIT_PROVIDER..."

# Créer .gitignore si absent
if [[ ! -f .gitignore ]]; then
  echo -e "node_modules/\n.env\n.DS_Store\n*.log" > .gitignore
  info ".gitignore créé"
fi

# Stager et committer les fichiers non commités
if [[ -n "$(git status --porcelain)" ]]; then
  git add -A
  git commit -m "chore: initial deployment via Forge"
  info "Commit initial créé"
else
  info "Rien à committer"
fi

# Push
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push -u origin "$CURRENT_BRANCH" 2>&1 | tail -3
info "Push vers origin/$CURRENT_BRANCH effectué"

# ─── Étape 6 : Lier le dépôt à Forge ─────────────────────────────────────────
if [[ "$SKIP_FORGE_LINK" == "true" ]]; then
  info "Liaison Forge ignorée (--no-forge)"
  exit 0
fi

step "5. Liaison du dépôt à Forge..."

# Résoudre SERVER_ID / SITE_ID si non fournis
if [[ -z "$SITE_ID" || -z "$SERVER_ID" ]]; then
  [[ -z "$SITE_DOMAIN" ]] && error "--site <domain> requis pour trouver le site Forge"
  info "Recherche du site '$SITE_DOMAIN' sur Forge..."

  SERVERS=$(forge_get "servers" | python3 -c "import sys,json; [print(s['id']) for s in json.load(sys.stdin)['servers']]")
  for SRV in $SERVERS; do
    MATCH=$(forge_get "servers/$SRV/sites" 2>/dev/null \
      | python3 -c "
import sys,json
for s in json.load(sys.stdin).get('sites',[]):
    if s['name']=='$SITE_DOMAIN': print(s['id'],'$SRV')
" 2>/dev/null || true)
    if [[ -n "$MATCH" ]]; then
      SITE_ID=$(echo "$MATCH" | awk '{print $1}')
      SERVER_ID=$(echo "$MATCH" | awk '{print $2}')
      info "Site trouvé : ID=$SITE_ID sur serveur=$SERVER_ID"
      break
    fi
  done
  [[ -z "$SITE_ID" ]] && error "Site '$SITE_DOMAIN' introuvable sur Forge"
fi

# Vérifier si un repo est déjà lié
EXISTING_REPO=$(forge_get "servers/$SERVER_ID/sites/$SITE_ID" \
  | python3 -c "import sys,json; s=json.load(sys.stdin)['site']; print(s.get('repository','') or '')")

if [[ -n "$EXISTING_REPO" && "$EXISTING_REPO" != "null" ]]; then
  warn "Un dépôt est déjà lié à ce site : $EXISTING_REPO"
  read -r -p "  Remplacer par $DETECTED_REPO ? [y/N] " confirm
  if [[ "${confirm,,}" != "y" ]]; then
    info "Liaison annulée"
    exit 0
  fi
  # Supprimer l'ancien projet Git
  curl -sf -X DELETE "${HFORGE[@]}" "$API/servers/$SERVER_ID/sites/$SITE_ID/git" > /dev/null 2>&1 || true
fi

# Installer le dépôt sur le site Forge
GIT_PAYLOAD=$(python3 -c "
import json
print(json.dumps({
  'provider': '$GIT_PROVIDER',
  'repository': '${DETECTED_REPO:-$FULL_REPO}',
  'branch': '$CURRENT_BRANCH',
  'composer': False
}))
")

forge_post "servers/$SERVER_ID/sites/$SITE_ID/git" "$GIT_PAYLOAD" > /dev/null
info "Dépôt $GIT_PROVIDER lié : ${DETECTED_REPO:-$FULL_REPO}@$CURRENT_BRANCH"

# Attendre que le statut soit installé
echo -n "  Attente"
for i in $(seq 1 20); do
  sleep 5
  REPO_STATUS=$(forge_get "servers/$SERVER_ID/sites/$SITE_ID" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['site'].get('repository_status','') or '')")
  echo -n "."
  [[ "$REPO_STATUS" == "installed" ]] && break
done
echo ""
info "Dépôt lié avec succès"

# Activer le quick deploy (auto-deploy sur push)
forge_post "servers/$SERVER_ID/sites/$SITE_ID/deployment" "{}" > /dev/null 2>&1 && \
  info "Quick deploy activé (auto-deploy sur git push)" || true

# ─── Résumé ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}✓ Git configuré et lié à Forge${NC}"
echo ""
echo "  Dépôt    : https://${GIT_PROVIDER}.com/${DETECTED_REPO:-$FULL_REPO}"
echo "  Branche  : $CURRENT_BRANCH"
echo "  Site ID  : $SITE_ID"
echo ""
echo "  Déployer manuellement :"
echo "    forge deploy ${SITE_DOMAIN:-}"
echo ""
echo "  Auto-deploy : git push origin $CURRENT_BRANCH → déploiement automatique"
