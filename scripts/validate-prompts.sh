#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_dir"

prompt_files=(
  prompts/core/household-assistant.md
  prompts/core/research-and-shopping.md
  prompts/optional/technical-assistant.md
  prompts/optional/personal-reflection.md
  prompts/optional/communication-coach.md
  prompts/optional/lifestyle-wellbeing.md
)

for path in "${prompt_files[@]}"; do
  if [[ ! -f $path ]]; then
    echo "required starter prompt missing: $path" >&2
    exit 1
  fi
  if ! rg -q '^# Role$' "$path"; then
    echo "starter prompt lacks a Role section: $path" >&2
    exit 1
  fi
done

python3 - <<'PY'
from pathlib import Path
import re

allowed = {"USER_NAME", "CURRENT_DATE"}
for path in sorted(Path("prompts").rglob("*.md")):
    if path.name == "README.md":
        continue
    text = path.read_text(encoding="utf-8")
    variables = {
        match.strip()
        for match in re.findall(r"{{\s*([^{}]+?)\s*}}", text)
    }
    unsupported = variables - allowed
    if unsupported:
        names = ", ".join(sorted(unsupported))
        raise SystemExit(f"{path}: unsupported Open WebUI variables: {names}")
PY

private_pattern='roger|sarah|tail82c''33|192\.168\.|/''Users/|/home/'
if rg -n -i "$private_pattern" prompts; then
  echo "possible private marker found in starter prompts" >&2
  exit 1
fi

python3 evaluations/validate_eval.py evals/assistant-prompts.jsonl
echo "starter prompt validation passed"
