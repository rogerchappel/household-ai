#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_dir"

for path in .env.example deploy/compose.yml deploy/searxng-settings.yml; do
  if [[ ! -f $path ]]; then
    echo "deployment file missing: $path" >&2
    exit 1
  fi
done

if rg -n 'image:.*:latest([[:space:]]|$)' deploy/compose.yml; then
  echo "deployment images must not use the latest tag" >&2
  exit 1
fi

required_patterns=(
  '127.0.0.1:3000:8080'
  'WEB_SEARCH_TRUST_ENV'
  'http_proxy: http://search-vpn:8888'
  'https_proxy: http://search-vpn:8888'
  'network_mode: "service:search-vpn"'
  'restart: unless-stopped'
)
for pattern in "${required_patterns[@]}"; do
  if ! rg -F -q "$pattern" deploy/compose.yml; then
    echo "required deployment invariant missing: $pattern" >&2
    exit 1
  fi
done

if [[ -f .env ]]; then
  mode=$(stat -f '%Lp' .env 2>/dev/null || stat -c '%a' .env)
  if [[ $mode != 600 ]]; then
    echo "private .env must have mode 600" >&2
    exit 1
  fi
fi

compose=()
if docker compose version >/dev/null 2>&1; then
  compose=(docker compose)
elif command -v docker-compose >/dev/null 2>&1 \
  && docker-compose version >/dev/null 2>&1; then
  compose=(docker-compose)
fi

if [[ ${#compose[@]} -gt 0 ]]; then
  env \
    WEBUI_URL=https://household-ai.example.invalid \
    WEBUI_SECRET_KEY=placeholder-webui-secret \
    SEARXNG_SECRET=placeholder-search-secret \
    INFERENCE_API_BASE_URL=https://model-host.example.invalid:8443/v1 \
    INFERENCE_NO_PROXY_HOST=model-host.example.invalid \
    INFERENCE_API_KEY=placeholder-inference-key \
    VPN_SERVICE_PROVIDER=surfshark \
    VPN_TYPE=wireguard \
    WIREGUARD_PRIVATE_KEY=placeholder-wireguard-key \
    WIREGUARD_ADDRESSES=10.0.0.2/32 \
    VPN_SERVER_COUNTRIES=Example \
    TZ=Etc/UTC \
    "${compose[@]}" -f deploy/compose.yml config --quiet
  echo "Docker Compose render: passed"
else
  echo "warning: Docker Compose unavailable; static deployment checks only" >&2
fi

echo "deployment validation passed"
