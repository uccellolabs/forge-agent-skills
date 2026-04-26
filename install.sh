#!/usr/bin/env bash
# install.sh — Installe les forge-agent-skills dans ~/.cursor/skills/
#
# Usage:
#   bash install.sh            # installe tous les skills
#   bash install.sh --unlink   # supprime les symlinks

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}!${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.cursor/skills"
UNLINK=false

[[ "${1:-}" == "--unlink" ]] && UNLINK=true

SKILLS=(
  forge-cli-setup
  forge-cli-servers
  forge-cli-sites
  forge-api-provision
  forge-deploy-automation
  ovh-dns-forge
)

mkdir -p "$TARGET_DIR"

for skill in "${SKILLS[@]}"; do
  src="$SCRIPT_DIR/$skill"
  dst="$TARGET_DIR/$skill"

  if [[ "$UNLINK" == "true" ]]; then
    if [[ -L "$dst" ]]; then
      rm "$dst"
      info "Symlink supprimé : $dst"
    else
      warn "Pas de symlink pour $skill (ignoré)"
    fi
    continue
  fi

  if [[ ! -d "$src" ]]; then
    warn "Dossier introuvable : $src (ignoré)"
    continue
  fi

  if [[ -L "$dst" ]]; then
    warn "Symlink déjà existant pour $skill — mise à jour"
    rm "$dst"
  elif [[ -d "$dst" ]]; then
    warn "$skill existe déjà comme dossier réel (non remplacé). Supprimer manuellement si besoin."
    continue
  fi

  ln -s "$src" "$dst"
  info "Installé : $skill → $dst"
done

if [[ "$UNLINK" == "false" ]]; then
  echo ""
  echo -e "${GREEN}Installation terminée.${NC}"
  echo "  Les skills sont disponibles dans Cursor automatiquement."
  echo ""
  echo "  Pour vérifier :"
  echo "    ls -la $TARGET_DIR"
fi
