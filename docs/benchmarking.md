# Benchmarking and model selection

The benchmark answers a practical question: which model and runtime provide the
best usable chat or coding experience on the computers available to this
household?

## Evidence required

Each run should record:

- anonymised node identifier and hardware class;
- operating-system version;
- runtime name, version, revision, and accelerator backend;
- model source revision, artifact size, hash, and quantization;
- context size, prompt and generation lengths, repetitions, threads, batch
  settings, and accelerator offload;
- prompt-processing speed, generation speed, first-token latency when
  available, task latency, and peak memory;
- completion and behavioural evaluation outcomes; and
- warnings, swapping, thermal limitations, or competing workloads.

Raw logs and model responses belong under `results/raw/`, which is ignored by
Git. Only sanitised summaries should be committed.

## Benchmark sequence

1. Inventory the machine and confirm the intended accelerator is visible.
2. Estimate safe model capacity while reserving operating-system headroom.
3. Select a small smoke-test model and verify result capture.
4. Run comparable dense candidates using standard prompt and generation sizes.
5. Test native runtime alternatives such as MLX on Apple Silicon.
6. Test larger or MoE candidates only when their complete weights fit safely.
7. Run chat, coding, tool-use, and independent-judgment evaluations.
8. Repeat sustained tests for finalists and observe memory and temperature.
9. Produce separate recommendations for household chat and programming.

## Standard performance run

The initial reference comparison uses:

| Setting | Value |
| --- | ---: |
| Prompt tokens | 512 |
| Generated tokens | 128 |
| Repetitions | 3 |
| Accelerator offload | Full, when safe |
| Flash attention | Automatic |

A shorter run is a smoke test and must be labelled as such. Do not compare a
quiet machine with one that is simultaneously serving another large model.

## How selection works

Throughput alone does not select the winner. Score each candidate for its
intended role:

| Dimension | Household chat | Programming |
| --- | ---: | ---: |
| Answer and task quality | High | High |
| Independent judgment | High | High |
| Tool and instruction following | High | High |
| Generation speed | Medium | High |
| First-token latency | High | Medium |
| Memory headroom and stability | High | High |
| Long-context behaviour | Medium | High |

An MoE model may perform fewer calculations per generated token, but its entire
quantized weight set still needs to be loaded or mapped. Use total artifact and
runtime memory—not active parameter count—to decide whether it fits.

Reject or qualify a candidate when it swaps heavily, exhausts memory, uses an
unintended CPU fallback, changes correct answers under pressure, invents APIs,
ignores exact-output requirements, or recommends unsafe actions.
