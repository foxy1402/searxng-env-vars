FROM ghcr.io/searxng/searxng:latest

# Bake in settings.yml so JSON format is enabled from first boot.
# The SearXNG entrypoint only creates settings.yml when it does not already
# exist, so this file is used as-is and never overwritten at runtime.
COPY settings.yml /etc/searxng/settings.yml
