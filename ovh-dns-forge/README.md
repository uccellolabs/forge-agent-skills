# ovh-dns-forge

Agent skill — Configure OVHcloud DNS zones to point a domain to a Laravel Forge server, using the [OVHcloud MCP server](https://labs.ovhcloud.com/en/mcp-server/).

No API keys to manage — authentication is handled via OAuth2 through the MCP.

Triggers automatically when you ask to configure DNS on OVH, point a domain to Forge, create A records, or refresh an OVH zone.

---

## Prerequisites

### OVHcloud MCP server

The OVHcloud MCP must be configured in Cursor. Add it to `~/.cursor/mcp.json`:

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

Restart Cursor after editing this file. The first MCP call will prompt you to authenticate via OVHcloud OAuth2.

> MCP documentation: [labs.ovhcloud.com/en/mcp-server/](https://labs.ovhcloud.com/en/mcp-server/)

### Forge CLI (to get server IP)

```bash
forge server:list   # note the IP of your Forge server
```

### dig (DNS verification)

Pre-installed on macOS. On Linux:

```bash
sudo apt install dnsutils
```

---

## Installation

### Cursor

```bash
ln -s ~/.cursor/skills/forge-agent-skills/ovh-dns-forge \
      ~/.cursor/skills/ovh-dns-forge

# Or install all skills
bash ~/.cursor/skills/forge-agent-skills/install.sh
```

### Claude Desktop

> The OVHcloud MCP is a Cursor/MCP feature and is not directly available in Claude Desktop. For Claude, configure DNS manually via the OVH Control Panel or use the OVHcloud API.

If you want to use this skill as a reference in Claude Desktop, paste the content of [`SKILL.md`](./SKILL.md) into a Claude Project.

### Claude Code

The OVHcloud MCP can be used with any MCP-compatible client. Add to your `CLAUDE.md`:

```markdown
## OVH DNS
~/.cursor/skills/forge-agent-skills/ovh-dns-forge/SKILL.md
```

---

## What this skill covers

| MCP Tool | Action |
|---|---|
| `get-domain-zone-list` | List all DNS zones on the OVH account |
| `get-domain-zone-record-list` | List records (filterable by type/subdomain) |
| `get-domain-zone-record-details` | Get a record by ID |
| `create-domain-zone-record` | Create an A record |
| `update-domain-zone-record-details` | Update an existing record |
| `refresh-domain-zone-zone` | Apply changes (always required after create/update) |

---

## Usage

### Standard workflow

The agent handles this end-to-end when you ask it to configure DNS. The steps it follows:

1. `forge server:list` → get the server IP
2. `get-domain-zone-record-list` → check existing A records
3. `create-domain-zone-record` or `update-domain-zone-record-details` → create/update
4. `refresh-domain-zone-zone` → apply changes
5. `dig +short monsite.com @8.8.8.8` → verify propagation

### DNS records for Forge

| Record | subDomain | Type | Notes |
|---|---|---|---|
| Root | `""` | A | Points to Forge server IP |
| www | `"www"` | A | A record (not CNAME — required for SSL) |
| Subdomain | `"app"` | A | For `app.domain.com` |

**TTL**: use `300` during changes, raise to `3600` afterwards.

### DNS must propagate before SSL

```bash
# Check propagation
dig +short monsite.com @8.8.8.8

# Then request the Let's Encrypt certificate
bash ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/ssl.sh \
  --site monsite.com
```

---

## Full workflow (DNS → Forge → SSL)

```bash
# 1. Get Forge server IP
forge server:list

# 2. Configure DNS (via OVHcloud MCP — agent handles this)
# "Configure DNS for monsite.com pointing to 1.2.3.4 on OVH"

# 3. Wait for propagation
dig +short monsite.com @8.8.8.8

# 4. Provision or just add SSL to an existing site
bash ~/.cursor/skills/forge-agent-skills/forge-deploy-automation/ssl.sh \
  --site monsite.com
```

---

## Part of

[forge-agent-skills](../) — complete Laravel Forge automation skills collection.
