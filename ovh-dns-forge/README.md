# ovh-dns-forge

Agent skill — Configure OVHcloud DNS zones to point a domain to a Laravel Forge server, using the [OVHcloud MCP server](https://labs.ovhcloud.com/en/mcp-server/). No API keys to manage — authentication via OAuth2.

---

## What you can say to the agent

```
"Configure DNS on OVH to point monsite.com to my Forge server"
"Create an A record for app.monsite.com with IP 1.2.3.4"
"Also add the www record"
"Check if DNS has propagated for nordvik.uccello.io"
"Refresh the OVH DNS zone for uccello.io"
"What DNS records exist for monsite.com on OVH?"
```

The agent retrieves the server IP from Forge, creates or updates the DNS records on OVH, refreshes the zone, and verifies propagation — without you needing to touch the OVH Control Panel.

---

## Installation

### Cursor

```bash
ln -s ~/.cursor/skills/forge-agent-skills/ovh-dns-forge \
      ~/.cursor/skills/ovh-dns-forge

# Or install all skills
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

Then add the OVHcloud MCP to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "ovhcloud": {
      "url": "https://mcp.eu.ovhcloud.com/mcp",
      "transport": "http"
    }
  }
}
```

Restart Cursor. The first call will prompt you to authenticate via OVHcloud OAuth2.

### Claude Desktop

> The OVHcloud MCP is available in any MCP-compatible client. For Claude Desktop, add the MCP server to your Claude configuration, or configure DNS manually via the [OVH Control Panel](https://www.ovh.com/manager/).

Paste [`SKILL.md`](./SKILL.md) into a Claude Project for reference.

### Claude Code

```markdown
## OVH DNS
~/.cursor/skills/forge-agent-skills/ovh-dns-forge/SKILL.md
```

---

## Prerequisites

### OVHcloud MCP

Add to `~/.cursor/mcp.json` (see Installation above). No API key or token needed — OAuth2 handles authentication.

### Forge CLI (to get server IP)

```bash
forge server:list   # note the IP of your target server
```

### dig (DNS verification)

Pre-installed on macOS. On Linux: `sudo apt install dnsutils`

---

## DNS records for Forge

| Record | subDomain | Type | Notes |
|---|---|---|---|
| Root | `""` | A | Points to Forge server IP |
| www | `"www"` | A | A record, not CNAME (required for SSL) |
| Subdomain | `"app"` | A | For `app.domain.com` |

**TTL**: use `300` during changes, raise to `3600` afterwards.

---

## MCP tools available

| Tool | Action |
|---|---|
| `get-domain-zone-list` | List all DNS zones on the account |
| `get-domain-zone-record-list` | List records (filterable by type/subdomain) |
| `create-domain-zone-record` | Create an A record |
| `update-domain-zone-record-details` | Update an existing record |
| `refresh-domain-zone-zone` | Apply changes (**always required** after create/update) |

---

## Manual reference

```bash
# Verify DNS propagation
dig +short monsite.com @8.8.8.8
dig +short www.monsite.com @8.8.8.8

# Check OVH nameservers
dig NS monsite.com   # should return ns*.ovh.net
```

---

## DNS must propagate before SSL

```bash
# Wait for propagation, then request Let's Encrypt
bash ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/ssl.sh \
  --site monsite.com
```

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
