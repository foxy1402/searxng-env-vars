# SearXNG on Claw Cloud (Kubernetes Pod, Env Vars Only)

This guide is for your exact setup:
- 1 container image: `ghcr.io/searxng/searxng:latest`
- Config from env vars only
- 1 public port for the website
- Optional 1 GB persistent mount

## 1) Pod/App settings in Claw Cloud

- Image: `ghcr.io/searxng/searxng:latest`
- Container port: `8080/TCP`
- Public port/ingress: map to container `8080/TCP` (not UDP)
- Persistent storage: mount to `/var/cache/searxng` (recommended)

Protocol note:
- SearXNG serves HTTP, so use TCP only.
- Do not open UDP for this app.

## 2) Required env vars

Use these env vars in your Claw Cloud app config:

```env
SEARXNG_BASE_URL=http://tcp.ap-southeast-1.clawcloudrun.com:33225/
SEARXNG_SECRET=replace-with-64-hex
SEARXNG_PUBLIC_INSTANCE=false
SEARXNG_LIMITER=false
SEARXNG_IMAGE_PROXY=true
SEARXNG_METHOD=GET
SEARXNG_DEBUG=false
```

Recommended config for your use case (Telegram bot + Perplexity clone, high query rate):

```env
SEARXNG_BASE_URL=http://tcp.ap-southeast-1.clawcloudrun.com:33225/
SEARXNG_SECRET=replace-with-64-hex
SEARXNG_PUBLIC_INSTANCE=false
SEARXNG_LIMITER=false
SEARXNG_IMAGE_PROXY=true
SEARXNG_METHOD=GET
SEARXNG_DEBUG=false
```

Notes:
- `SEARXNG_BASE_URL` must end with `/`
- `SEARXNG_BASE_URL` must match your real public URL exactly (host + port + protocol)
- `SEARXNG_SECRET` should be random and long
- Keep `SEARXNG_PUBLIC_INSTANCE=false` when `SEARXNG_LIMITER=false` and no Valkey is configured
- With `SEARXNG_LIMITER=false`, protect your endpoint at app level (API key, allowlist, or gateway rules) if abuse appears

Generate `SEARXNG_SECRET` online (no local tool needed):

- [Browserling Random Hex](https://www.browserling.com/tools/random-hex)
  - Set `How many digits?` = `64`
  - Copy generated value into `SEARXNG_SECRET`
- [CalcBE Token Generator](https://calcbe.com/en/tools/token-generator/)
  - Format: `hex`
  - Bytes: `32` (this gives 64 hex characters)
  - Copy generated value into `SEARXNG_SECRET`

## 3) Two-step deploy on Claw Cloud (because port is random)

1. First deploy with a temporary base URL, for example:
   - `SEARXNG_BASE_URL=http://localhost:8080/`
2. After Claw Cloud gives your public endpoint (example: `http://tcp.ap-southeast-1.clawcloudrun.com:33225/`), update `SEARXNG_BASE_URL` to that exact value.
3. Redeploy/restart the pod.

If Claw Cloud gives you HTTPS instead of HTTP, use `https://...` in `SEARXNG_BASE_URL`.

## 4) Recommended Command/Arguments (1 worker, bot optimized)

If your platform only exposes env vars plus startup `Command`/`Arguments`, use this startup command to create `settings.yml` at boot.
This profile keeps 1 worker, enables JSON format, and disables engines that are commonly failing in your logs.

Set startup as (for platforms with 1 Command field + 1 Arguments field):

Command:

```text
/bin/sh -c
```

Arguments:

```text
printf '%s\n' 'use_default_settings: true' 'server:' '  public_instance: false' '  limiter: false' 'search:' '  formats:' '    - json' 'engines:' '  - name: ahmia' '    disabled: true' '  - name: torch' '    disabled: true' '  - name: startpage' '    disabled: true' >/etc/searxng/settings.yml; exec /usr/local/searxng/.venv/bin/granian --interface wsgi --host 0.0.0.0 --port 8080 --workers 1 searx.webapp:app
```

Then restart and test:

```text
http://tcp.ap-northeast-1.clawcloudrun.com:41874/search?q=bitcoin&format=json
```

Expected result: JSON response (not 403).

## 5) If you want true public-instance mode later

If you set `SEARXNG_PUBLIC_INSTANCE=true`, SearXNG enables bot protections that require Valkey and limiter config.
Without Valkey, startup can fail with:
- `missing config file: /etc/searxng/limiter.toml`
- `The limiter requires Valkey`

For your current "no limit, high query rate" scope, keep:
- `SEARXNG_PUBLIC_INSTANCE=false`
- `SEARXNG_LIMITER=false`

## 6) About "only I can change settings"

SearXNG does not provide a global admin settings page for server config.
Server settings are changed via environment/config + restart only.
That means only the person with access to your Claw Cloud project can change settings.

Public users can still use the search page normally.

## 7) What users can do on the website

- Use your URL as a public meta-search engine
- Search results are fetched from upstream engines (DuckDuckGo/Brave/etc depending on SearXNG defaults and engine availability)
- Users cannot change your server-side env config
