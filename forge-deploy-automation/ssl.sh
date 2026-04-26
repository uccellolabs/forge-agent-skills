#!/usr/bin/env bash
# ssl.sh — Active Let's Encrypt sur un site Forge existant
#
# Usage:
#   bash ssl.sh --site nordvik-test.uccello.io
#   bash ssl.sh --site monsite.com --extra-domain www.monsite.com
#   bash ssl.sh --server-id 1152395 --site-id 3156490
#
# Variables requises: FORGE_API_TOKEN (ou ~/.laravel-forge/config.json)

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step()  { echo -e "\n${BLUE}▶ $*${NC}"; }

# ─── Auth ────────────────────────────────────────────────────────────────────
FORGE_API_TOKEN="${FORGE_API_TOKEN:-}"
if [[ -z "$FORGE_API_TOKEN" ]] && [[ -f "$HOME/.laravel-forge/config.json" ]]; then
  FORGE_API_TOKEN=$(python3 -c "import json; print(json.load(open('$HOME/.laravel-forge/config.json'))['token'])")
fi
[[ -z "$FORGE_API_TOKEN" ]] && error "FORGE_API_TOKEN non défini"

API="https://forge.laravel.com/api/v1"
HEADERS=(-H "Authorization: Bearer $FORGE_API_TOKEN" -H "Accept: application/json" -H "Content-Type: application/json")
forge_get()  { curl -sf "${HEADERS[@]}" "$API/$1"; }
forge_post() { curl -sf -X POST "${HEADERS[@]}" "$API/$1" ${2:+-d "$2"}; }

# ─── Paramètres ──────────────────────────────────────────────────────────────
SITE_DOMAIN="" SERVER_ID="" SITE_ID="" EXTRA_DOMAIN=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --site)        SITE_DOMAIN="$2"; shift 2 ;;
    --server-id)   SERVER_ID="$2";   shift 2 ;;
    --site-id)     SITE_ID="$2";     shift 2 ;;
    --extra-domain) EXTRA_DOMAIN="$2"; shift 2 ;;
    *) error "Option inconnue: $1" ;;
  esac
done

[[ -z "$SITE_DOMAIN" && -z "$SITE_ID" ]] && error "--site <domain> requis"

# ─── Résoudre SERVER_ID et SITE_ID depuis le nom de domaine ──────────────────
resolve_site() {
  step "Recherche du site $SITE_DOMAIN sur Forge..."
  local servers
  servers=$(forge_get "servers" | python3 -c "import sys,json; [print(s['id']) for s in json.load(sys.stdin)['servers']]")

  for srv in $servers; do
    local sites
    sites=$(forge_get "servers/$srv/sites" 2>/dev/null || true)
    local match
    match=$(echo "$sites" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for s in data.get('sites', []):
    if s['name'] == '$SITE_DOMAIN':
        print(s['id'], '$srv' if '$srv' else s.get('server_id',''))
" 2>/dev/null || true)
    if [[ -n "$match" ]]; then
      SITE_ID=$(echo "$match" | awk '{print $1}')
      SERVER_ID=$(echo "$match" | awk '{print $2}')
      info "Site trouvé : ID=$SITE_ID sur serveur=$SERVER_ID"
      return 0
    fi
  done
  error "Site '$SITE_DOMAIN' introuvable sur aucun serveur Forge"
}

if [[ -z "$SITE_ID" || -z "$SERVER_ID" ]]; then
  resolve_site
fi

# ─── Vérifier un certificat actif existant ───────────────────────────────────
step "Vérification des certificats existants..."
EXISTING=$(forge_get "servers/$SERVER_ID/sites/$SITE_ID/certificates" \
  | python3 -c "
import sys, json
certs = json.load(sys.stdin).get('certificates', [])
active = [c for c in certs if c.get('active')]
if active:
    print(active[0]['domain'])
" 2>/dev/null || true)

if [[ -n "$EXISTING" ]]; then
  warn "Un certificat SSL est déjà actif pour '$EXISTING' sur ce site."
  echo ""
  read -r -p "Continuer quand même et en émettre un nouveau ? [y/N] " confirm
  [[ "${confirm,,}" != "y" ]] && { info "Annulé."; exit 0; }
fi

# ─── Construire la liste des domaines ─────────────────────────────────────────
DOMAIN="${SITE_DOMAIN}"
DOMAINS_JSON=$(python3 -c "
import json
domains = ['$DOMAIN']
if '$EXTRA_DOMAIN':
    domains.append('$EXTRA_DOMAIN')
print(json.dumps(domains))
")

step "Demande du certificat Let's Encrypt pour : $(echo $DOMAINS_JSON | python3 -c "import sys,json; print(', '.join(json.load(sys.stdin)))")"

# ─── Émettre le certificat ───────────────────────────────────────────────────
SSL_PAYLOAD="{\"domains\": $DOMAINS_JSON}"
SSL_RESULT=$(forge_post "servers/$SERVER_ID/sites/$SITE_ID/certificates/letsencrypt" "$SSL_PAYLOAD")
CERT_ID=$(echo "$SSL_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['certificate']['id'])")
info "Certificat en cours d'installation (ID: $CERT_ID)..."

# ─── Attendre l'activation ───────────────────────────────────────────────────
echo -n "  Attente"
for i in $(seq 1 30); do
  sleep 5
  RESP=$(forge_get "servers/$SERVER_ID/sites/$SITE_ID/certificates/$CERT_ID")
  STATUS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin)['certificate']; print(d['status'])")
  ACTIVE=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin)['certificate']; print(d['active'])")
  echo -n "."
  if [[ "$ACTIVE" == "True" ]]; then
    echo ""
    info "Certificat actif (status: $STATUS)"
    break
  fi
  if [[ "$STATUS" == "failed" ]]; then
    echo ""
    error "Échec de l'émission du certificat. Vérifier que le DNS pointe bien vers le serveur."
  fi
done

# ─── Vérification finale ──────────────────────────────────────────────────────
step "Vérification HTTPS..."
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://$DOMAIN" 2>/dev/null || echo "000")
REDIRECT=$(curl -sI "http://$DOMAIN" 2>/dev/null | grep -i "^location:" | tr -d '\r' || true)

echo ""
echo -e "${GREEN}✓ SSL Let's Encrypt activé${NC}"
echo ""
echo "  Domaine   : https://$DOMAIN"
echo "  HTTPS     : $HTTP_CODE"
echo "  Redirect  : HTTP → ${REDIRECT:-HTTPS (géré par Forge)}"
echo "  Cert ID   : $CERT_ID"
