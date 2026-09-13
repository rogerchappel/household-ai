# Household AI

Household AI is a benchmark-first toolkit for turning computers you already own
into a private, useful AI service for everyone in the household.

Instead of guessing which local model will fit, the project inventories each
machine, benchmarks realistic candidates, compares performance and behaviour,
and records why a particular model and runtime were selected. The chosen model
can then be exposed through an OpenAI-compatible API for chat interfaces and
coding tools.

## Version 0.1 scope

The first release intentionally covers one tested deployment shape:

- an Apple Silicon Mac using MLX or llama.cpp with Metal;
- an Ubuntu Linux machine using llama.cpp with Vulkan;
- SSH-based inventory and benchmark orchestration;
- dense and mixture-of-experts model comparisons;
- chat, coding, and independent-judgment evaluations;
- a multi-user Open WebUI deployment;
- web search through SearXNG with optional VPN egress;
- private remote access through Tailscale; and
- backup, health-check, context-management, and restart guidance.

Windows, Home Assistant, wake-word hardware, and additional tool integrations
are future work. They are not part of the initial support promise.

## Tested reference hardware

The initial reference deployment uses the following anonymised hardware. These
results are examples, not universal performance claims.

| Node | Hardware | Memory | Runtime paths evaluated | Intended role |
| --- | --- | ---: | --- | --- |
| Apple node | Apple M4, 10-core CPU and 10-core GPU | 24 GB unified | MLX, llama.cpp Metal | General chat, review, smaller models |
| Linux node | Ryzen 9 8945HS, Radeon 780M | 64 GB system | llama.cpp Vulkan | Larger MoE models, primary inference |

See [the example benchmark report](examples/reference-benchmark.md) for the
kind of evidence the selection process should produce.

## Project principles

- Measure the actual machine instead of selecting from model marketing alone.
- Keep enough memory headroom for the operating system and concurrent users.
- Evaluate answer quality and behaviour as well as tokens per second.
- Treat model output, downloaded content, and web pages as untrusted input.
- Keep credentials, model weights, raw chats, and private knowledge out of Git.
- Require human approval for security-sensitive or destructive operations.
- Clearly distinguish tested, expected, experimental, and unsupported paths.

## Status

This repository is being assembled from a working private deployment. The first
milestone is a reproducible benchmark and a documented deployment for the two
tested platforms. It is not yet a one-command installer.

## First useful commands

Collect a privacy-safe local inventory:

```bash
python3 hardware/inventory.py --label apple-01
```

Inspect the benchmark and evaluation workflows before downloading models:

```bash
benchmarks/benchmark-llama.sh --help
benchmarks/benchmark-mlx.sh --help
python3 evaluations/run_eval.py --help
```

Validate the repository:

```bash
bash scripts/validate-repository.sh
```

After a model and inference runtime have been selected, follow the
[version 0.1 deployment guide](docs/deployment.md) to configure the private
multi-user web interface and VPN-routed search.

## Project documentation

The [documentation index](docs/README.md) links the complete version 0.1
workflow. Planned work is tracked in the [roadmap](ROADMAP.md), and notable
changes are recorded in the [changelog](CHANGELOG.md).

Contributions are welcome; read the [contributing guide](CONTRIBUTING.md) and
[security policy](SECURITY.md) before opening a pull request or vulnerability
report.

## Repository layout

```text
benchmarks/   Reproducible performance runners
deploy/       Sanitised Open WebUI and private-search control plane
docs/         Scope, architecture, setup, and operating guidance
evals/        Synthetic chat and coding evaluation cases
evaluations/  Validation and local evaluation runners
examples/     Sanitised inventories and benchmark reports
skills/       Agent-assisted installation workflow
```

## Safety boundary

The installation workflow may inspect remote hardware and propose commands, but
it must not silently change operating systems, authentication, firewall rules,
VPN settings, production services, or persistent data. Those actions require a
clear plan and explicit approval from the system owner.
