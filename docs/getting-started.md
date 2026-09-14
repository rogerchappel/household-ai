# Getting started

This guide takes a new owner from a clean checkout to a reviewed plan. It does
not silently install software, download large models, or change remote systems.

## Before you begin

Version 0.1 expects:

- one Apple Silicon Mac or Ubuntu 24.04 machine to run the workflow;
- at least one supported Mac or Ubuntu inference candidate;
- wired Ethernet between machines where practical;
- enough free storage for candidate model files;
- SSH key access to remote candidates; and
- a coding agent or comfort following the linked terminal steps.

Windows can be a client, but is not a supported v0.1 inference host. A former
Windows mini PC can join the verified path after a deliberate Ubuntu install;
this project does not automate repartitioning or operating-system replacement.

## 1. Clone and check the workstation

```bash
git clone https://github.com/rogerchappel/household-ai.git
cd household-ai
bash scripts/preflight.sh
bash scripts/validate-repository.sh
```

Preflight is read-only. A failed optional check does not install anything; it
points to the relevant setup stage.

## 2. Prepare remote access

Use a separate SSH key for setup automation and protect it with normal file
permissions. Add its public half to each candidate machine. Confirm that an
interactive connection works before involving an agent:

```bash
ssh your-node-alias
```

Prefer aliases in `~/.ssh/config` so commands and reports do not spread local IP
addresses or usernames. Never paste or commit a private key. See
[hardware discovery](hardware-discovery.md) for the minimal inventory process.

## 3. Ask a coding agent to guide the workflow

The repository includes an installer skill designed for Codex, Claude Code,
and similar agents that can read local files and use SSH. Start the agent in the
repository and use a prompt like:

> Use `skills/household-ai-installer/SKILL.md` to guide this installation. Begin
> with read-only preflight and inventory only. My candidate SSH aliases are
> `apple-node` and `linux-node`. Do not install packages, download models, change
> services, or expose ports until you show me the plan and I approve that phase.

Replace the example aliases. The agent should report its scope, risk, proposed
downloads, verification, and rollback before each mutating stage.

## 4. Inventory and shortlist

Collect the smallest useful inventory on each node:

```bash
python3 hardware/inventory.py --label apple-node
ssh linux-node 'python3 -' < hardware/inventory.py --label linux-node
```

Keep raw inventories private. Commit only sanitised facts such as processor,
memory class, accelerator, and approximate available storage.

Use [benchmarking](benchmarking.md) to shortlist a few licensed candidates that
fit with operating-system, context, and concurrency headroom. An MoE model's
active parameter count describes compute, not the full memory needed to store
its weights.

## 5. Benchmark before choosing

After reviewing model licences and approving the stated download size, run the
same prompt and generation settings across candidates. Record:

- prompt processing and generation speed;
- first-token and end-to-end latency;
- peak memory and swap use;
- temperature and sustained stability;
- usable context at intended concurrency; and
- coding, household-answer, and independent-judgment quality.

The benchmark scripts and evaluation fixtures are described in
[benchmarking](benchmarking.md) and [evaluations](evaluations.md). Use the
[reference report](../examples/reference-benchmark.md) as a format, not as a
promise that its winner will suit different hardware.

## 6. Promote, deploy, and verify

Promotion freezes the accepted artifact, runtime, offload, context, cache, and
parallelism settings behind a stable OpenAI-compatible model name. Follow
[model promotion](model-promotion.md), then [deployment](deployment.md).

Do not call the setup complete until another tailnet device can:

1. sign in with its intended account;
2. complete a normal chat;
3. use a permitted assistant without seeing private assistants or knowledge;
4. return cited results for a current web query when search is enabled; and
5. reconnect after a controlled restart;
6. launch Open WebUI from a phone home-screen icon over private HTTPS; and
7. request microphone access successfully when voice input is intended.

Also verify an isolated backup restoration before relying on the system.

## Where to go next

- [Version 0.1 scope and support matrix](v0.1-scope.md)
- [Documentation index](README.md)
- [Project roadmap](../ROADMAP.md)
- [Security policy](../SECURITY.md)
