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
printf '%s\n' 'use_default_settings: true' 'server:' '  public_instance: false' '  limiter: false' 'search:' '  formats:' '    - html' '    - json' 'engines:' '  - name: ahmia' '    disabled: true' '  - name: torch' '    disabled: true' '  - name: startpage' '    disabled: true' >/etc/searxng/settings.yml; exec /usr/local/searxng/.venv/bin/granian --interface wsgi --host 0.0.0.0 --port 8080 --workers 1 searx.webapp:app
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

---

## 8) Alternative: Deploy on Portainer (Docker) on Oracle Linux

This section covers deploying SearXNG using Portainer's Docker management UI on an Oracle Linux server.

### 8.1) Prerequisites

- Oracle Linux 8 or 9 with Docker CE installed
- Portainer CE running (typically on port `9443` for HTTPS UI)
- A public/elastic IP assigned to your Oracle Cloud instance
- SSH access to the server for firewall configuration

Install Docker (if not already):

```bash
sudo dnf install -y dnf-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
```

Install Portainer (if not already):

```bash
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 \
  --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts
```

### 8.2) Oracle Linux Firewall & Ingress Port Configuration

Oracle Linux uses `firewalld` by default. You must open the port SearXNG will be published on (e.g., `8080/tcp`) in **both** the OS firewall and the Oracle Cloud security list/NSG.

**Step 1 — OS firewall (firewalld):**

```bash
# Open port 8080 (or whichever host port you choose)
sudo firewall-cmd --permanent --add-port=8080/tcp

# If you need Portainer UI accessible externally too
sudo firewall-cmd --permanent --add-port=9443/tcp

# Reload to apply
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

If your Oracle Linux uses `iptables` instead of `firewalld`:

```bash
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 9443 -j ACCEPT
sudo iptables-save | sudo tee /etc/sysconfig/iptables
```

**Step 2 — Oracle Cloud ingress rules (VCN Security List or NSG):**

1. Go to **Oracle Cloud Console** → **Networking** → **Virtual Cloud Networks**
2. Select your VCN → **Security Lists** (or **Network Security Groups**)
3. Add an **Ingress Rule**:
   - Source CIDR: `0.0.0.0/0` (or restrict to your IP)
   - IP Protocol: `TCP`
   - Destination Port Range: `8080`
4. (Optional) Add another ingress rule for port `9443` if you want remote Portainer access

Without both OS-level and cloud-level rules, traffic will be blocked even if Docker is listening.

### 8.3) Deploy via Portainer — Option A: Docker Compose Stack

In Portainer, go to **Stacks** → **Add stack** → **Web editor**, and paste:

```yaml
version: "3.8"

services:
  searxng:
    image: ghcr.io/searxng/searxng:latest
    container_name: searxng
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - SEARXNG_BASE_URL=http://<YOUR_SERVER_PUBLIC_IP>:8080/
      - SEARXNG_SECRET=replace-with-64-hex
      - SEARXNG_PUBLIC_INSTANCE=false
      - SEARXNG_LIMITER=false
      - SEARXNG_IMAGE_PROXY=true
      - SEARXNG_METHOD=GET
      - SEARXNG_DEBUG=false
    volumes:
      - searxng_data:/var/cache/searxng
    command: >
      /bin/sh -c "
      printf '%s\n'
        'use_default_settings: true'
        'server:'
        '  public_instance: false'
        '  limiter: false'
        'search:'
        '  formats:'
        '    - html'
        '    - json'
        'engines:'
        '  - name: ahmia'
        '    disabled: true'
        '  - name: torch'
        '    disabled: true'
        '  - name: startpage'
        '    disabled: true'
        > /etc/searxng/settings.yml &&
      exec /usr/local/searxng/.venv/bin/granian
        --interface wsgi --host 0.0.0.0 --port 8080
        --workers 1 searx.webapp:app
      "

volumes:
  searxng_data:
```

Replace `<YOUR_SERVER_PUBLIC_IP>` with your Oracle instance's public IP.

Click **Deploy the stack**.

### 8.4) Deploy via Portainer — Option B: Single Container

1. In Portainer, go to **Containers** → **Add container**
2. Fill in:
   - **Name:** `searxng`
   - **Image:** `ghcr.io/searxng/searxng:latest`
3. Under **Network ports configuration**, publish:
   - Host: `8080` → Container: `8080` (TCP)
4. Under **Env** (environment variables), add each:
   | Name | Value |
   |------|-------|
   | `SEARXNG_BASE_URL` | `http://<YOUR_SERVER_PUBLIC_IP>:8080/` |
   | `SEARXNG_SECRET` | `replace-with-64-hex` |
   | `SEARXNG_PUBLIC_INSTANCE` | `false` |
   | `SEARXNG_LIMITER` | `false` |
   | `SEARXNG_IMAGE_PROXY` | `true` |
   | `SEARXNG_METHOD` | `GET` |
   | `SEARXNG_DEBUG` | `false` |
5. Under **Volumes**, bind:
   - Volume: `searxng_data` → Container: `/var/cache/searxng`
6. Under **Command**, set:
   - Command: `/bin/sh -c`
   - Arguments (same startup command from Section 4)
7. Under **Restart policy**, select **Unless stopped**
8. Click **Deploy the container**

### 8.5) Verify the deployment

```bash
# From the server itself
curl -s http://localhost:8080/search?q=test&format=json | head -c 200

# From your local machine (replace with your server IP)
curl -s http://<YOUR_SERVER_PUBLIC_IP>:8080/search?q=test&format=json | head -c 200
```

Expected: JSON search results (not 403 or connection refused).

If you get **connection refused** from your local machine:
1. Check `firewalld`/`iptables` rules on the server
2. Check Oracle Cloud VCN security list ingress rules
3. Confirm the container is running: `docker ps` or check Portainer dashboard

### 8.6) HTTPS with reverse proxy (optional)

For HTTPS, put a reverse proxy (Nginx, Caddy, or Traefik) in front of SearXNG:

```bash
# Example: Caddy as a reverse proxy (auto HTTPS with Let's Encrypt)
docker run -d --name caddy --restart unless-stopped \
  -p 80:80 -p 443:443 \
  -v caddy_data:/data \
  caddy:latest caddy reverse-proxy --from your-domain.com --to localhost:8080
```

Then update:
- `SEARXNG_BASE_URL=https://your-domain.com/`
- Open ports `80/tcp` and `443/tcp` in both firewalld and Oracle Cloud security list
