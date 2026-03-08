# SearXNG Public Deployment (Env Vars Only)

This stack runs:
- `ghcr.io/searxng/searxng:latest`
- `caddy:2-alpine` as reverse proxy with HTTPS and basic-auth protection for settings-like pages.

## 1) Prepare env vars

```powershell
Copy-Item .env.example .env
```

Edit `.env` and set:
- `SEARXNG_BASE_URL` to your final domain URL (with trailing slash).
- `SEARXNG_SECRET` to a strong random value.
- `DOMAIN` and `ACME_EMAIL`.
- `ADMIN_USER` and `ADMIN_PASSWORD_HASH`.

Generate secrets:

```powershell
# 64 hex chars for SearXNG secret
openssl rand -hex 32

# bcrypt hash for settings-page password
docker run --rm caddy:2-alpine caddy hash-password --plaintext "your-strong-password"
```

## 2) Start

```powershell
docker compose pull
docker compose up -d
```

## 3) Behavior

- Public users can search without limiter (`SEARXNG_LIMITER=false`).
- Paths `/preferences`, `/stats`, and `/config` require basic auth.
- Only someone with your `ADMIN_USER` + password can access those pages.

## 4) Update to newest images

```powershell
docker compose pull
docker compose up -d
```