# Context management

Local models have a finite context window. Every request may include the system
prompt, conversation history, files, retrieved knowledge, tool definitions,
tool results, and the requested response. A large advertised window is useful
only when the runtime has enough memory and prompt-processing speed to serve it.

## Three different limits

Keep these distinct:

1. **Runtime context** — the total context allocated by the inference server.
2. **Per-request or per-slot context** — the usable share when the server runs
   concurrent slots.
3. **Client payload** — what Open WebUI, OpenCode, or another client sends before
   the user types a meaningful message.

A coding client with large agent instructions and loaded skills can exceed a
small context window on its first request. Repeated client-side compaction cannot
reliably rescue a fixed initial prompt that is already too large.

## Enable Open WebUI compaction

Open WebUI includes server-side context compaction. In the current interface:

1. open **Settings > Admin > Experience > Interface**;
2. enable **Context Compaction**;
3. choose a reliable task model for summaries;
4. set the threshold below the model's measured per-request context;
5. keep a useful share of recent messages verbatim; and
6. optionally provide a neutral summary prompt that preserves decisions,
   unresolved questions, sources, and safety constraints.

The feature summarizes older turns for the request while keeping the displayed
chat stored in full. The `/compact` chat command requests compaction immediately.

For a measured 64K per-slot window, a starting threshold around 45K–50K leaves
room for system instructions, search results, retrieval, tool schemas, and the
reply. Measure the real prompt size and lower it if tool-heavy turns still
overflow.

Background task settings are separate from ordinary model defaults. Confirm the
task model and its context are suitable for summaries, titles, search queries,
and other background work.

## Compaction is a relief valve

Compaction is not a hard token cap. A single enormous message or attachment may
still exceed the model window before there is a safe conversational cut point.
Use upload limits, retrieval, a purpose-built filter, or a larger context for
that case.

Summaries are lossy. Do not rely on chat history as the only record of passwords,
medical instructions, legal decisions, commitments, or operational runbooks.

## Avoid empty post-tool responses

A turn that shows compaction or web searches but no final answer is incomplete.
Test and monitor the complete loop:

1. the model requests a permitted tool;
2. the tool returns bounded results;
3. results fit inside the remaining context;
4. the model receives the tool result; and
5. the model emits a final user-facing answer with citations where applicable.

If the last step is missing, inspect service logs for request size, timeout,
stop reason, tool-call loop, and upstream HTTP status. During privacy-sensitive
debugging, use timestamps, request IDs, token counts, status codes, and duration;
do not collect prompt text, tool content, or conversation bodies.

Common corrections are:

- lower the compaction threshold;
- reduce search result count or retrieved chunk size;
- use a faster, reliable task model for compaction;
- reserve more generation tokens;
- ensure the base model supports the selected tool-calling mode;
- cap tool iterations and total request duration; and
- start a new chat when a single oversized turn cannot be compacted safely.

## Acceptance test

Before promoting a context configuration:

1. measure idle memory at the intended context and concurrency;
2. send the coding client's real initial prompt;
3. run a long multi-turn chat past the compaction threshold;
4. run a web-search turn after compaction;
5. confirm the final answer is present and cited;
6. run two concurrent requests when two slots are promised; and
7. record latency, peak memory, swap, errors, and whether key facts survived the
   summary.

See [model promotion](model-promotion.md) for the settings that must be frozen
after acceptance. Open WebUI's current behaviour is documented in its
[official context-management guide](https://docs.openwebui.com/getting-started/essentials/#context-management).
