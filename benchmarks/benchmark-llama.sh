#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: benchmark-llama.sh --binary PATH --model PATH --label NAME [options]

Options:
  --device NAME       Explicit llama.cpp device, such as MTL0 or Vulkan0
  --gpu-layers N      Layers to offload to the accelerator (default: 99)
  --threads N         CPU thread count (otherwise llama-bench chooses its default)
  --prompt N          Prompt tokens per test (default: 512)
  --generate N        Generated tokens per test (default: 128)
  --repetitions N     Repetitions per test (default: 3)
  --results-dir PATH  Output root (default: results/raw)
EOF
}

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
binary=
model=
label=
device=
gpu_layers=99
threads=
prompt_tokens=512
generated_tokens=128
repetitions=3
results_dir="$repo_dir/results/raw"

while [[ $# -gt 0 ]]; do
  case $1 in
    --binary) binary=${2-}; shift 2 ;;
    --model) model=${2-}; shift 2 ;;
    --label) label=${2-}; shift 2 ;;
    --device) device=${2-}; shift 2 ;;
    --gpu-layers) gpu_layers=${2-}; shift 2 ;;
    --threads) threads=${2-}; shift 2 ;;
    --prompt) prompt_tokens=${2-}; shift 2 ;;
    --generate) generated_tokens=${2-}; shift 2 ;;
    --repetitions) repetitions=${2-}; shift 2 ;;
    --results-dir) results_dir=${2-}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z $binary || -z $model || -z $label ]]; then
  usage >&2
  exit 2
fi
if [[ ! -x $binary ]]; then
  echo "benchmark binary is not executable: $binary" >&2
  exit 1
fi
if [[ ! -f $model ]]; then
  echo "model file does not exist: $model" >&2
  exit 1
fi
if [[ ! $label =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "label may contain only letters, numbers, dots, underscores, and hyphens" >&2
  exit 2
fi
for value in "$gpu_layers" "$prompt_tokens" "$generated_tokens" "$repetitions"; do
  if [[ ! $value =~ ^[0-9]+$ ]]; then
    echo "layer and token settings must be non-negative integers" >&2
    exit 2
  fi
done
if [[ $prompt_tokens -eq 0 || $generated_tokens -eq 0 || $repetitions -eq 0 ]]; then
  echo "token counts and repetitions must be positive integers" >&2
  exit 2
fi
if [[ -n $threads && ! $threads =~ ^[1-9][0-9]*$ ]]; then
  echo "threads must be a positive integer" >&2
  exit 2
fi

host_name=$(hostname -s)
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
run_dir="$results_dir/$label/${host_name}-${timestamp}"
mkdir -p "$run_dir"
runtime_version=reported-in-benchmark-jsonl
server_binary=$(dirname "$binary")/llama-server
if [[ -x $server_binary ]]; then
  runtime_version=$($server_binary --version 2>&1 | sed -n '/^version:/p; /^built with/p' | tr '\n' ' ')
fi

if command -v sha256sum >/dev/null; then
  model_sha256=$(sha256sum "$model" | awk '{print $1}')
else
  model_sha256=$(shasum -a 256 "$model" | awk '{print $1}')
fi
if stat -f %z "$model" >/dev/null 2>&1; then
  model_bytes=$(stat -f %z "$model")
else
  model_bytes=$(stat -c %s "$model")
fi

{
  printf 'timestamp_utc=%s\n' "$timestamp"
  printf 'host=%s\n' "$host_name"
  printf 'system=%s\n' "$(uname -a)"
  printf 'binary=%s\n' "$binary"
  printf 'runtime_version=%s\n' "$runtime_version"
  printf 'model=%s\n' "$model"
  printf 'model_bytes=%s\n' "$model_bytes"
  printf 'model_sha256=%s\n' "$model_sha256"
  printf 'device=%s\n' "${device:-auto}"
  printf 'gpu_layers=%s\n' "$gpu_layers"
  printf 'threads=%s\n' "${threads:-runtime-default}"
  printf 'prompt_tokens=%s\n' "$prompt_tokens"
  printf 'generated_tokens=%s\n' "$generated_tokens"
  printf 'repetitions=%s\n' "$repetitions"
} >"$run_dir/metadata.txt"

command=(
  "$binary"
  --model "$model"
  --n-prompt "$prompt_tokens"
  --n-gen "$generated_tokens"
  --repetitions "$repetitions"
  --n-gpu-layers "$gpu_layers"
  --flash-attn auto
  --output jsonl
)
if [[ -n $device ]]; then
  command+=(--device "$device")
fi
if [[ -n $threads ]]; then
  command+=(--threads "$threads")
fi

"${command[@]}" >"$run_dir/benchmark.jsonl" 2>"$run_dir/runtime.log"

echo "Benchmark complete: $run_dir"
echo "Metadata: $run_dir/metadata.txt"
echo "Results: $run_dir/benchmark.jsonl"
echo "Runtime log: $run_dir/runtime.log"
