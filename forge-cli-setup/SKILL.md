---
name: forge-cli-setup
description: Install, authenticate, and configure the Laravel Forge CLI. Use when the user mentions forge login, forge token, FORGE_API_TOKEN, installing forge cli, or setting up forge access for the first time.
---

# Forge CLI — Setup & Authentication

## Installation

```bash
composer global require laravel/forge-cli
```

Requires PHP 8.0+. Verify: `forge --version`

## Authentication

Generate an API token at: https://forge.laravel.com/profile/api

```bash
# Interactive login
forge login

# Direct token (CI/CD friendly)
forge login --token=your-api-token

# CI/CD: set environment variable instead
export FORGE_API_TOKEN=your-api-token
```

Token stored in `~/.laravel-forge/config.json` after login.

## SSH Key Configuration

Required before using `forge ssh`, `forge command`, `forge tinker`, or `forge database:shell`.

```bash
# Test SSH access on current server
forge ssh:test

# Auto-configure (uses default ~/.ssh/id_rsa.pub)
forge ssh:configure

# Specify key and name
forge ssh:configure --key=~/.ssh/id_ed25519.pub --name=my-macbook
```

## Server Selection

All CLI commands run against the **active server**.

```bash
forge server:list          # List available servers
forge server:current       # Show active server
forge server:switch        # Interactive picker
forge server:switch staging # Switch by name
```

## Global Options

| Option | Effect |
|--------|--------|
| `-n` | Non-interactive (no prompts) |
| `-q` | Quiet output |
| `-v/-vv/-vvv` | Verbosity level |

## Quick Verification

```bash
forge server:list   # Should list your servers
forge site:list     # Should list sites on active server
```
