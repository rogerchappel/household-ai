#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: benchmark-mlx.sh --python PATH --model-dir PATH --label NAME [options]

Options:
  --prompt N          Prompt tokens per trial (default: 512)
  --generate N        Generated tokens per trial (default: 128)
  --trials N          Number of timing trials (default: 3)
  --results-dir PATH  Output root (default: results/raw)
EOF
}

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
python=
model_dir=
label=
prompt_tokens=512
generated_tokens=128
trials=3
results_dir="$repo_dir/results/raw"

while [[ $# -gt 0 ]]; do
  case $1 in
    --python) python=${2-}; shift 2 ;;
    --model-dir) model_dir=${2-}; shift 2 ;;
    --label) label=${2-}; shift 2 ;;
    --prompt) prompt_tokens=${2-}; shift 2 ;;
    --generate) generated_tokens=${2-}; shift 2 ;;
    --trials) trials=${2-}; shift 2 ;;
    --results-dir) results_dir=${2-}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z $python || -z $model_dir || -z $label ]]; then
  usage >&2
  exit 2
fi
if [[ ! -x $python ]]; then
  echo "Python interpreter is not executable: $python" >&2
  exit 1
fi
if [[ ! -d $model_dir || ! -f $model_dir/config.json ]]; then
  echo "MLX model directory is incomplete: $model_dir" >&2
  exit 1
fi
if [[ ! $label =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "label may contain only letters, numbers, dots, underscores, and hyphens" >&2
  exit 2
fi
for value in "$prompt_tokens" "$generated_tokens" "$trials"; do
  if [[ ! $value =~ ^[1-9][0-9]*$ ]]; then
    echo "token counts and trials must be positive integers" >&2
    exit 2
  fi
done

hash_file() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

host_name=$(hostname -s)
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
run_dir="$results_dir/$label/${host_name}-${timestamp}"
mkdir -p "$run_dir"

while IFS= read -r -d '' file; do
  relative_path=${file#"$model_dir/"}
  printf '%s  %s\n' "$(hash_file "$file")" "$relative_path"
done < <(find "$model_dir" -type f ! -path '*/.cache/*' -print0) \
  | sort -k2 >"$run_dir/model-manifest.sha256"

package_versions=$($python - <<'PY'
from importlib.metadata import version
print(f"mlx={version('mlx')} mlx-lm={version('mlx-lm')}")
PY
)

{
  printf 'timestamp_utc=%s\n' "$timestamp"
  printf 'host=%s\n' "$host_name"
  printf 'system=%s\n' "$(uname -a)"
  printf 'python=%s\n' "$python"
  printf 'runtime_versions=%s\n' "$package_versions"
  printf 'model_dir=%s\n' "$model_dir"
  printf 'model_manifest_sha256=%s\n' "$(hash_file "$run_dir/model-manifest.sha256")"
  printf 'prompt_tokens=%s\n' "$prompt_tokens"
  printf 'generated_tokens=%s\n' "$generated_tokens"
  printf 'trials=%s\n' "$trials"
} >"$run_dir/metadata.txt"

"$python" -m mlx_lm.benchmark \
  --model "$model_dir" \
  --prompt-tokens "$prompt_tokens" \
  --generation-tokens "$generated_tokens" \
  --num-trials "$trials" \
  >"$run_dir/benchmark.txt" 2>"$run_dir/runtime.log"

echo "Benchmark complete: $run_dir"
echo "Metadata: $run_dir/metadata.txt"
echo "Model manifest: $run_dir/model-manifest.sha256"
echo "Results: $run_dir/benchmark.txt"
echo "Runtime log: $run_dir/runtime.log"
