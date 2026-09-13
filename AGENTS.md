# Agent Operating Instructions for Household AI

This repository contains tooling and guidance that may operate on remote
household computers. Keep every change reviewable, reversible, verifiable, and
safe for a non-technical system owner.

## Scope

- Version 0.1 supports Apple Silicon macOS and Ubuntu Linux.
- Windows, Home Assistant, and voice hardware are roadmap items only.
- Do not broaden the support matrix without repeatable tests on real hardware.
- Keep private deployments separate from reusable public defaults and examples.

## Privacy and security

- Never commit credentials, private keys, hostnames, IP addresses, usernames,
  email addresses, raw chats, private prompts, knowledge bases, backups, model
  weights, or unredacted command output from a household system.
- Use sanitised fixtures for examples and tests.
- Never read private conversations, prompts, or knowledge merely to validate
  infrastructure.
- Keep SSH private keys on the operator's machine. Install only public keys on
  target nodes.
- Prefer dedicated unprivileged service accounts and narrowly scoped elevation.
- Stop for explicit approval before changing authentication, authorization,
  firewalls, VPNs, operating systems, persistent data, production services,
  secrets, telemetry, licensing, or public API compatibility.

## Workflow

Before editing, report the objective, blast radius, likely files, commit plan,
verification plan, and risk level.

- Work on a branch created from the latest default branch.
- Use Conventional Commits and one reviewable intent per commit.
- Do not change more than three files in one commit without explicit maintainer
  approval for a coherent scaffold or generated change.
- Review status and diff before staging.
- Stage only files belonging to the current intent.
- Run the smallest relevant validation before committing.
- Do not merge or publish without explicit maintainer approval.

## Benchmark integrity

- Record the host class, operating system, runtime revision, model source,
  artifact hash, quantization, context, offload, threads, batch settings, and
  repetitions needed to reproduce a result.
- Compare candidates under equivalent settings where possible.
- Label smoke tests separately from selection benchmarks.
- Reject runs affected by another loaded model, memory exhaustion, swapping,
  thermal instability, or an unintended software-rendering fallback.
- Do not rank models on throughput alone. Include task completion, factual
  reliability, instruction following, tool use, and independent judgment.
- Never execute model-generated commands as part of an evaluation.

## Verification

Run `bash scripts/validate-repository.sh` when it exists. Until then, review
Markdown links, search for private identifiers and secrets, and manually inspect
the complete diff.

Return a review pack containing the repository, branch, task, status, summary,
commits, changed files, verification, risk, rollback plan, human decisions, and
recommended next task.
