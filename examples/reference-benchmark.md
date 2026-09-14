# Example: two-node benchmark report

This sanitised example shows the report format using measurements from the
initial reference deployment. It is evidence from one setup, not a promise of
performance on other computers.

## Inventory

| Node | Processor and accelerator | Memory | Operating system | Verified backend |
| --- | --- | ---: | --- | --- |
| `apple-01` | Apple M4, 10-core CPU and 10-core GPU | 24 GB unified | macOS | Metal and MLX |
| `linux-01` | Ryzen 9 8945HS, Radeon 780M | 64 GB system | Ubuntu 24.04 | Vulkan |

Both nodes used the same pinned llama.cpp revision for cross-machine GGUF
comparisons. The Apple-native comparison used a pinned MLX-LM environment.

## Performance grid

| Node | Candidate | Format and backend | Prompt tok/s | Generated tok/s | Peak memory | Notes |
| --- | --- | --- | ---: | ---: | ---: | --- |
| `apple-01` | Qwen3 14B | Q4_K_M GGUF, Metal | 107.8 | 10.09 | Not captured | Cross-node baseline |
| `linux-01` | Qwen3 14B | Q4_K_M GGUF, Vulkan | 190.8 | 9.31 | Not captured | Faster prompt ingestion |
| `apple-01` | Qwen3 14B | MLX 4-bit | 108.4 | 10.62 | 8.83 GB | Slightly faster generation than GGUF |
| `linux-01` | Qwen3-Coder 30B-A3B | Q4_K_M GGUF, Vulkan | 378.8 | 37.33 | Not captured | All 99 layers offloaded |

Settings: 512 prompt tokens, 128 generated tokens, three repetitions, full
accelerator offload, and automatic flash attention where applicable.

## Long-context service test

Short throughput tests did not predict the behaviour of a coding agent whose
bootstrap prompt exceeded 30,000 tokens. A separate sanitized service test used
the Linux node and the selected MoE model:

| Total context | Slots | Per-slot context | KV cache | Result |
| ---: | ---: | ---: | --- | --- |
| 32,768 | 2 | 16,384 | F16 | Agent bootstrap rejected as oversized |
| 65,536 | 1 | 65,536 | F16 | Fit, but long-context prefill was impractically slow |
| 65,536 | 1 | 65,536 | Q8_0 | Completed a 34,627-token exact-output request in 279 seconds client time |
| 131,072 | 2 | 65,536 | Q8_0 | Started without swap and completed two concurrent short requests in about 4.5 seconds each |

The result is specific to this model, runtime revision, and integrated GPU. It
shows why context pool size, slot count, KV-cache type, end-to-end agent prompts,
and concurrent use must be benchmarked together. It is not a universal
recommendation to enable Q8_0 or 131,072 tokens.

## Programming evaluation

| Node | Candidate | Mean task latency | Completed | Strict passes | Interpretation |
| --- | --- | ---: | ---: | ---: | --- |
| `apple-01` | Qwen2.5-Coder 7B MLX 4-bit | 16.06 s | 9/10 | 1/10 | Fast, but insufficient correctness |
| `apple-01` | Qwen3 14B MLX 4-bit | 32.80 s | 10/10 | 6/10 | Best tested Apple reviewer |
| `apple-01` | Qwen2.5-Coder 14B MLX 4-bit | 31.35 s | 10/10 | 3/10 | No quality advantage |
| `linux-01` | Qwen3-Coder 30B-A3B Q4_K_M | 8.86 s | 10/10 | 5/10 | Best interactive coding candidate |

Strict passes were manually reviewed against recorded expectations. They are a
diagnostic for this suite, not a general intelligence score.

## Behavioural comparison

A community-modified version of the MoE candidate generated at effectively the
same speed as the standard model, but accepted several false premises and unsafe
recommendations under user pressure. The performance difference therefore did
not justify the reliability regression.

## Example recommendation

| Role | Selected class | Reason | Required guardrail |
| --- | --- | --- | --- |
| General household chat | 14B-class 4-bit model | Fits the Apple node with useful headroom and stronger tested judgment | Verify important factual claims and use citations for current information |
| Fast programming drafts | 30B-A3B MoE Q4 on Linux | Highest observed generation speed with full offload | Run tests and require review for consequential changes |
| Independent code review | 14B-class model on Apple | Strongest strict pass result among tested Apple candidates | Do not treat agreement between related models as proof |

The main conclusion is not that these models are universally best. It is that
the larger MoE model was practical on the 64 GB Linux node but inappropriate for
the 24 GB Apple node, while the Apple-native 14B model provided a better balance
of quality, speed, and memory headroom there.
