# Connect coding clients

The promoted model service exposes one stable, authenticated endpoint to every
approved coding client on the tailnet. Connect clients directly to this model
API rather than routing them through Open WebUI.

## Connection contract

Replace the placeholders with values from the private promotion record:

| Client type | Base URL | Model |
| --- | --- | --- |
| OpenAI-compatible | `https://MODEL_HOST.TAILNET_NAME.ts.net:8443/v1` | `household-primary` |
| Anthropic Messages-compatible | `https://MODEL_HOST.TAILNET_NAME.ts.net:8443` | `household-primary` |

The second URL deliberately omits `/v1`; Anthropic-compatible clients append
their own `/v1/messages` path.

Every device must be signed in to the intended tailnet. Give each client its
own API key so one credential can be revoked without interrupting the others.
Keep keys in the client's credential store or a protected secret file, never in
Git, shell history, screenshots, command-line arguments, or diagnostic logs.

## OpenCode

Merge `deploy/model-service/opencode.provider.jsonc` into the user's global
OpenCode configuration and replace the hostname placeholder. Set the advertised
context to the per-slot value exposed by `/props`, not the server's total context
pool.

In OpenCode:

1. Run `/connect`.
2. Select **Other**.
3. Enter the provider ID `household`.
4. Add the dedicated OpenCode key.
5. Run `/models` and select `household/household-primary`.

Large third-party agent packs can contribute tens of thousands of tokens before
the user's first message. Measure their initial request and either allocate a
large enough slot or use a lean agent profile. Advertising a larger limit in
OpenCode does not increase the server's real capacity.

## OpenClaw

Register a custom OpenAI-compatible provider in `~/.openclaw/openclaw.json`.
This example uses an environment SecretRef; a file or external secret provider
is preferable for an always-on gateway:

```json5
{
  models: {
    mode: "merge",
    providers: {
      household: {
        baseUrl: "https://MODEL_HOST.TAILNET_NAME.ts.net:8443/v1",
        apiKey: "${HOUSEHOLD_MODEL_API_KEY}",
        api: "openai-completions",
        authHeader: true,
        timeoutSeconds: 600,
        models: [
          {
            id: "household-primary",
            name: "Household programming model",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 65536,
            contextTokens: 57344,
            maxTokens: 8192,
            compat: {
              toolSchemaProfile: "llamacpp",
              supportsTools: true
            }
          }
        ]
      }
    }
  }
}
```

Replace the example context values with the promoted per-slot limits, then
validate and probe the route:

```bash
openclaw config validate
openclaw models list --provider household
openclaw models status --probe --probe-provider household
```

Select `household/household-primary` for an agent only after its tools and
prompt fit within the promoted context budget.

## Claude Code

Current llama.cpp servers expose an Anthropic-compatible Messages API. Direct
Claude Code compatibility remains experimental because Claude Code can add new
gateway requirements and non-Claude models may behave differently with its
agent prompts.

For a single terminal session:

```bash
export ANTHROPIC_BASE_URL=https://MODEL_HOST.TAILNET_NAME.ts.net:8443
export ANTHROPIC_AUTH_TOKEN=use-a-dedicated-client-key
claude --model household-primary
```

Do not save the literal key in a repository or shared shell profile. Prefer a
credential helper, password manager, or launcher that reads a mode-`600` secret
file. Verify a short exact-output request and a read-only tool task before
allowing write operations.

## Other clients

Aider, Cline, Continue, editor extensions, and other clients that accept an
OpenAI-compatible provider normally require the `/v1` base URL, stable model
alias, and a bearer API key. Confirm that the client supports streamed Chat
Completions and structured tools before relying on it for agentic work.

## Troubleshooting

- `401` means the API key is missing or invalid.
- A connection failure usually means Tailscale is disconnected, the Serve
  route is absent, or the tailnet policy denies that device.
- A context-size error must be fixed on the server or by reducing the client
  prompt. Client metadata alone cannot create capacity.
- Repeated compaction on the first turn usually means the agent's bootstrap
  prompt already exceeds one server slot.
- Slow first-token latency with a large prompt can be normal even when the
  model fits; benchmark the complete client workflow, not only short prompts.

## References

- [OpenCode providers](https://opencode.ai/docs/providers)
- [OpenClaw custom providers](https://docs.openclaw.ai/gateway/config-tools/custom-providers)
- [Claude Code gateways](https://code.claude.com/docs/en/llm-gateway)
- [llama.cpp server API](https://github.com/ggml-org/llama.cpp/tree/master/tools/server)
