---
name: ovh-dns-forge
description: Configure OVH DNS zone to point a domain to a Laravel Forge server using the OVHcloud MCP. Manages A records, CNAME, zone refresh. Use when the user wants to point an OVH domain to Forge, create or update DNS records on OVH, or configure a domain after provisioning a Forge site.
---

# OVH DNS — Pointer un domaine vers Laravel Forge

Utilise exclusivement le **MCP OVHcloud** (configuré dans `~/.cursor/mcp.json`).
Authentification OAuth2 automatique — aucune clé API à gérer.

## Workflow standard

### 1. Récupérer l'IP du serveur Forge

```bash
forge server:list   # relever l'IP du serveur cible
```

### 2. Vérifier les enregistrements existants

Appeler le MCP :
```
get-domain-zone-record-list  zoneName=uccello.io  fieldType=A  subDomain=monsite
```

### 3. Créer ou mettre à jour les enregistrements A

**Si aucun enregistrement existant** → `create-domain-zone-record` :
```json
{ "zoneName": "uccello.io", "requestBody": { "fieldType": "A", "subDomain": "monsite", "target": "1.2.3.4", "ttl": 300 } }
```

**Si un enregistrement existe** → `update-domain-zone-record-details` avec son `id`.

### 4. Rafraîchir la zone (obligatoire)

```
refresh-domain-zone-zone  zoneName=uccello.io
```

### 5. Vérifier la propagation

```bash
dig +short monsite.uccello.io @8.8.8.8
```

## Règles DNS pour Forge

| Enregistrement | subDomain | Type | Notes |
|---|---|---|---|
| Racine (`@`) | `""` | A | Pointe vers l'IP Forge |
| www | `"www"` | A | A record, pas CNAME (SSL) |
| Sous-domaine | `"app"` | A | Pour `app.monsite.com` |

- **TTL recommandé** : `300` lors d'un changement, remonter à `3600` ensuite
- **DNS doit être propagé** avant de demander le certificat Let's Encrypt
- Vérifier les NS avec `dig NS monsite.com` — doit retourner `ns*.ovh.net`

## Outils MCP disponibles

| Outil | Action |
|---|---|
| `get-domain-zone-list` | Lister toutes les zones DNS du compte |
| `get-domain-zone-record-list` | Lister les enregistrements (filtrable par type/subDomain) |
| `get-domain-zone-record-details` | Détails d'un enregistrement par ID |
| `create-domain-zone-record` | Créer un enregistrement |
| `update-domain-zone-record-details` | Modifier un enregistrement existant |
| `refresh-domain-zone-zone` | Appliquer les changements (toujours après création/modif) |

## Workflow complet Forge + OVH + SSL

```
1. forge server:list           → noter l'IP
2. MCP OVH : créer A record   → sous-domaine → IP
3. MCP OVH : refresh zone
4. dig +short ... @8.8.8.8    → vérifier propagation
5. SSL via Forge API           → voir skill forge-api-provision
```
