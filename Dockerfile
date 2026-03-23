FROM ghcr.io/searxng/searxng:latest

# Bake in settings.yml so JSON format is enabled from first boot.
# The SearXNG entrypoint only creates settings.yml when it does not already
# exist, so this file is used as-is and never overwritten at runtime.
COPY settings.yml /etc/searxng/settings.yml

# Provide limiter.toml so SearXNG does not log a warning about the missing
# file on every startup (limiter is disabled in settings.yml, but the
# botdetection module still looks for this file).
COPY limiter.toml /etc/searxng/limiter.toml
