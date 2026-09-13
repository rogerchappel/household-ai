#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_dir"

required_files=(
  README.md
  AGENTS.md
  CHANGELOG.md
  CODE_OF_CONDUCT.md
  CONTRIBUTING.md
  ROADMAP.md
  SECURITY.md
  .github/pull_request_template.md
  docs/README.md
  docs/stackforge.md
  docs/v0.1-scope.md
  docs/benchmarking.md
  docs/evaluations.md
  docs/hardware-discovery.md
  docs/model-promotion.md
  docs/deployment.md
  benchmarks/benchmark-llama.sh
  benchmarks/benchmark-mlx.sh
  deploy/compose.yml
  deploy/model-service/household-model.service
  deploy/model-service/inference.env.example
  deploy/model-service/opencode.provider.jsonc
  deploy/searxng-settings.yml
  evaluations/run_eval.py
  evaluations/validate_eval.py
  hardware/inventory.py
  scripts/validate-deployment.sh
  scripts/validate-model-promotion.sh
  skills/household-ai-installer/SKILL.md
)
for path in "${required_files[@]}"; do
  if [[ ! -f $path ]]; then
    echo "required file missing: $path" >&2
    exit 1
  fi
done

git diff --check
bash -n benchmarks/benchmark-llama.sh
bash -n benchmarks/benchmark-mlx.sh
python3 -m py_compile \
  evaluations/run_eval.py \
  evaluations/validate_eval.py \
  hardware/inventory.py
python3 evaluations/validate_eval.py evals/independent-judgment.jsonl
python3 evaluations/validate_eval.py evals/coding.jsonl
bash scripts/validate-deployment.sh
bash scripts/validate-model-promotion.sh

python3 - <<'PY'
from pathlib import Path
import re

root = Path.cwd()
skill = (root / "skills/household-ai-installer/SKILL.md").read_text(encoding="utf-8")
if not re.match(r"^---\n(?s:.*?)\n---\n", skill):
    raise SystemExit("skill frontmatter is missing or malformed")
frontmatter = skill.split("---", 2)[1]
for field in ("name:", "description:"):
    if field not in frontmatter:
        raise SystemExit(f"skill frontmatter is missing {field[:-1]}")

broken = []
for source in root.rglob("*.md"):
    if ".git" in source.parts:
        continue
    for target in re.findall(r"\[[^]]+\]\(([^)]+)\)", source.read_text(encoding="utf-8")):
        if target.startswith(("http://", "https://", "#")):
            continue
        path = target.split("#", 1)[0]
        if path and not (source.parent / path).resolve().exists():
            broken.append(f"{source.relative_to(root)}: {target}")
if broken:
    raise SystemExit("broken local links:\n" + "\n".join(broken))
PY

private_pattern='tail82c33|192\.168\.|/Users/|BEGIN (OPENSSH|RSA|EC) PRIVATE KEY'
if rg -n -i "$private_pattern" . \
  --glob '!.git/**' \
  --glob '!scripts/validate-repository.sh'; then
  echo "possible private deployment marker found" >&2
  exit 1
fi

if command -v gitleaks >/dev/null 2>&1; then
  gitleaks git . --redact --no-banner
else
  echo "warning: gitleaks unavailable; skipped history-wide secret scan" >&2
fi

echo "repository validation passed"
