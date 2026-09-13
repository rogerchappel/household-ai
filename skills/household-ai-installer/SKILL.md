---
name: household-ai-installer
description: Inventory Apple Silicon macOS and Ubuntu Linux computers over SSH, benchmark compatible local LLM candidates, explain the best model and runtime for each role, and guide a reviewed Household AI deployment. Use when setting up or reassessing a private household AI system with the Household AI repository.
---

# Household AI installer

Help a system owner turn supported computers into a measured, private household
AI deployment. Optimise for a reliable outcome that a non-technical owner can
understand and operate.

Version 0.1 requires a local checkout, Bash, SSH access to target nodes, and
owner approval for downloads or system changes. It supports Apple Silicon macOS
and Ubuntu Linux.

## Start with the repository

1. Find the repository root and read `docs/v0.1-scope.md`,
   `docs/hardware-discovery.md`, and `docs/benchmarking.md` completely.
2. Inspect the current branch, status, and available scripts.
3. Do not claim support for a platform outside the documented matrix.
4. Preserve an existing deployment unless the owner explicitly asks to replace
   or change it.

## Establish the boundary

Before changing anything, report:

- the requested outcome;
- participating computers and their intended roles;
- expected files and systems affected;
- staged implementation and commit plan;
- verification and rollback plan; and
- risk level.

Read [the safety boundaries](references/safety-boundaries.md) before configuring
SSH, installing packages, downloading models, or changing a running service.

## Discover without mutating

Begin with read-only checks. For each node, collect only the technical facts
needed for model selection:

- anonymised node label;
- operating system and version;
- CPU and accelerator model;
- physical or unified memory;
- available storage;
- supported accelerator devices and runtime versions; and
- current large-model processes that could invalidate a benchmark.

Do not include usernames, addresses, hostnames, serial numbers, private paths,
credentials, or unrelated process arguments in a committed report. Store raw
inventory under `inventory/private/` and commit only a sanitised summary.

Use `hardware/inventory.py` for supported nodes rather than assembling a broad
diagnostic command that might expose unrelated environment or process data.

If SSH is not ready, explain the manual bootstrap steps. Never ask the owner to
paste a private key into chat or commit one to the repository.

## Build a candidate plan

Use memory headroom, backend compatibility, intended context, and concurrency
to shortlist models. Include dense and MoE candidates when appropriate.

- Calculate fit from the complete artifact and expected runtime allocations.
- Do not use an MoE model's active parameter count as its memory requirement.
- Identify model source, revision, quantization, approximate download size, and
  licence before requesting download approval.
- Prefer a small smoke-test artifact before downloading several large models.
- Separate candidates for household chat, programming, and independent review.

Present the proposed downloads and estimated total storage before downloading
them. Continue only after the owner approves that cost and licence boundary.

## Benchmark consistently

Use `benchmarks/benchmark-llama.sh` for comparable GGUF runs and
`benchmarks/benchmark-mlx.sh` for Apple-native MLX runs.

1. Confirm the intended accelerator rather than a software CPU fallback.
2. Unload competing large models.
3. Run a labelled smoke test.
4. Run the standard 512-prompt, 128-generation, three-repetition comparison.
5. Compare full and partial offload only when both configurations are safe.
6. Observe memory pressure and temperature during finalist runs.
7. Run applicable quality and behavioural evaluations.
8. Treat empty, truncated, timed-out, or errored outputs as incomplete tests.

Never execute code or commands produced by a candidate model merely because it
was generated during an evaluation.

## Recommend before deploying

Use [the report format](references/recommendation-report.md). Explain why each
selected model fits its node and role. Distinguish measurements from inference,
and state every missing test.

Throughput is not sufficient evidence. Prefer the model that best balances:

- useful answer and coding quality;
- independent judgment and factual reliability;
- tool and instruction following;
- interactive latency;
- memory headroom and sustained stability; and
- expected household concurrency.

Ask the owner to approve the recommendation before installing or replacing a
long-running service.

## Deploy in reviewed stages

Make the smallest reversible change, verify it, and record rollback before
continuing. Authentication, authorization, firewall, VPN, remote-access,
telemetry, boot, and persistent-data changes always require explicit approval.

At completion, verify the inference API, web interface, permitted users, web
search when enabled, restart recovery, backup path, and rollback procedure.
Return a plain-English handoff plus a technical review pack.
