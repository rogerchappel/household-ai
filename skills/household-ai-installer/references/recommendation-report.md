# Recommendation report format

Use a compact report that a non-technical owner can understand and a maintainer
can reproduce.

## Environment

| Node | Hardware class | Memory | Operating system | Verified accelerator | Proposed role |
| --- | --- | ---: | --- | --- | --- |

Use anonymised node labels. State whether every row is measured or inferred.

## Candidate results

| Node | Candidate | Quantization | Context | Offload | Prompt tok/s | Generated tok/s | Peak memory | Quality result | Status |
| --- | --- | --- | ---: | --- | ---: | ---: | ---: | --- | --- |

Use `not captured` rather than inventing a value. Mark smoke tests separately.

## Recommendation

| Role | Selected model and runtime | Why it fits | Known limitations | Required guardrail |
| --- | --- | --- | --- | --- |

Provide separate rows for household chat, programming, and independent review
when the evidence supports separate choices.

## Decision narrative

In plain language, explain:

1. which candidates were rejected for memory, speed, quality, or stability;
2. whether an MoE candidate fully fit in accelerator-accessible memory;
3. whether full offload materially improved the result;
4. what remained responsive under the expected number of users;
5. which conclusions came from measurement and which remain assumptions; and
6. the estimated downloads, storage use, and services to be changed.

## Approval checkpoint

End the pre-deployment report with the exact proposed changes, their rollback,
and the decisions the owner must approve. Do not proceed merely because the
benchmark produced a winner.
