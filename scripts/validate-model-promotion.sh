#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_dir"

required_files=(
  deploy/model-service/household-model.service
  deploy/model-service/inference.env.example
  deploy/model-service/opencode.provider.jsonc
  docs/model-promotion.md
)

for path in "${required_files[@]}"; do
  if [[ ! -s $path ]]; then
    echo "model promotion file missing or empty: $path" >&2
    exit 1
  fi
done

service=deploy/model-service/household-model.service
if ! rg -q -- '--host 127\.0\.0\.1' "$service"; then
  echo "model service must bind to loopback" >&2
  exit 1
fi
if rg -q -- '--host (0\.0\.0\.0|::)' "$service"; then
  echo "model service must not bind to every interface" >&2
  exit 1
fi
for required_flag in --alias --jinja --api-key-file --no-webui; do
  if ! rg -q -- "$required_flag" "$service"; then
    echo "model service is missing $required_flag" >&2
    exit 1
  fi
done

python3 - <<'PY'
import json
from pathlib import Path

path = Path("deploy/model-service/opencode.provider.jsonc")
config = json.loads(path.read_text(encoding="utf-8"))
provider = config["provider"]["household"]
base_url = provider["options"]["baseURL"]
if not base_url.startswith("https://") or not base_url.endswith("/v1"):
    raise SystemExit("OpenCode endpoint must be an HTTPS /v1 URL")
if "apiKey" in provider["options"]:
    raise SystemExit("OpenCode template must not contain an API key")
model = config["model"]
if model != "household/household-primary":
    raise SystemExit("OpenCode default must use the stable household alias")
if "household-primary" not in provider["models"]:
    raise SystemExit("OpenCode provider is missing the stable model alias")
PY

for phrase in \
  'tailscale serve --bg --https=8443' \
  'tailscale serve --https=8443 off' \
  'An SSH tunnel is a temporary diagnostic path'; do
  if ! rg -q --fixed-strings "$phrase" docs/model-promotion.md; then
    echo "model promotion guide is missing invariant: $phrase" >&2
    exit 1
  fi
done

echo "model promotion validation passed"
