# SearXNG on Claw Cloud (Kubernetes Pod, Env Vars Only)

This guide is for your exact setup:
- 1 container image: `ghcr.io/searxng/searxng:latest`
- Config from env vars only
- 1 public port for the website
- Optional 1 GB persistent mount

## 1) Pod/App settings in Claw Cloud

- Image: `ghcr.io/searxng/searxng:latest`
- Container port: `8080`
- Public port/ingress: map to container `8080`
- Persistent storage: mount to `/var/cache/searxng` (recommended)

## 2) Required env vars

Use these env vars in your Claw Cloud app config:

```env
SEARXNG_BASE_URL=https://your-domain.example/
SEARXNG_SECRET=replace-with-64-hex
SEARXNG_PUBLIC_INSTANCE=true
SEARXNG_LIMITER=false
SEARXNG_IMAGE_PROXY=true
SEARXNG_METHOD=GET
SEARXNG_DEBUG=false
```

Notes:
- `SEARXNG_BASE_URL` must end with `/`
- `SEARXNG_SECRET` should be random and long
- `SEARXNG_LIMITER=false` means no built-in rate limit for public users

Generate a secret example:

```bash
openssl rand -hex 32
```

## 3) About "only I can change settings"

SearXNG does not provide a global admin settings page for server config.
Server settings are changed via environment/config + restart only.
That means only the person with access to your Claw Cloud project can change settings.

Public users can still use the search page normally.

## 4) What users can do on the website

- Use your URL as a public meta-search engine
- Search results are fetched from upstream engines (DuckDuckGo/Brave/etc depending on SearXNG defaults and engine availability)
- Users cannot change your server-side env config
