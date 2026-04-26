---
name: forge-cli-servers
description: Manage Laravel Forge servers via CLI — list, switch, monitor resources (Nginx, PHP, database, daemons). Use when the user asks about forge server commands, checking resource status, restarting services, or viewing server logs.
---

# Forge CLI — Server Management

## Server Navigation

```bash
forge server:list          # List all servers
forge server:current       # Show active server
forge server:switch        # Interactive picker
forge server:switch prod   # Switch by name
```

## Resource Status

```bash
forge nginx:status
forge database:status
forge php:status           # Default PHP version
forge php:status 8.3       # Specific version
forge daemon:status
```

## Resource Logs

```bash
forge nginx:logs           # Error logs
forge nginx:logs access    # Access logs
forge database:logs
forge php:logs             # Default PHP
forge php:logs 8.3
forge daemon:logs
forge daemon:logs --follow # Realtime streaming
```

## Restart Resources

```bash
forge nginx:restart
forge database:restart
forge php:restart
forge php:restart 8.3
forge daemon:restart
```

## SSH Access

```bash
forge ssh                  # Connect as forge user
forge ssh server-name
forge ssh --user=root
```

## Daemon Management

```bash
forge daemon:list
forge daemon:status
forge daemon:logs
forge daemon:restart
```

## Database Shell

```bash
forge database:shell                    # Default DB as forge user
forge database:shell my_db
forge database:shell my_db --user=root
```

## Typical Troubleshooting Workflow

1. `forge server:switch <name>` — target the right server
2. `forge nginx:status` / `forge php:status` — check service health
3. `forge nginx:logs` — inspect errors
4. `forge nginx:restart` — restart if needed
5. `forge site:logs` — check app-level errors
