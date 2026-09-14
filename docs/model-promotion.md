# Promote a benchmarked model into service

Promotion turns a benchmark winner into a stable household service. It is a
reviewed deployment decision, not an automatic consequence of receiving the
highest benchmark score.

Version 0.1 provides a persistent Ubuntu and llama.cpp path. Other runtimes may
be used when they expose the same authenticated OpenAI-compatible API, stable
model ID, health check, and private network boundary, but they remain
experimental until their service lifecycle has been tested.

## Promotion contract

Record these values in the private recommendation report before changing the
host:

| Setting | Source |
| --- | --- |
| Model artifact and hash | Accepted benchmark run |
| Runtime binary and revision | Accepted benchmark run |
| Context, parallel slots, KV-cache types, and GPU offload | Stable finalist configuration |
| Stable model alias | Household role, such as `household-primary` |
| Model host | Device that completed the accepted run |
| API and Tailscale ports | Reviewed deployment plan |
| Rollback service or model | Existing working deployment |

Clients use the stable alias, never the GGUF filename. A later model can take
over `household-primary` after it passes the same gates without requiring every
client to change configuration.

## Resulting architecture

```text
Open WebUI and coding clients
          |
          | authenticated HTTPS inside the tailnet
          v
model-host.example.ts.net:8443
          |
          | Tailscale Serve, tailnet only
          v
llama-server on 127.0.0.1:18080
          |
          v
approved model artifact
```

Use Tailscale Serve, not Funnel. An SSH tunnel is a temporary diagnostic path,
not the normal client configuration.

## 1. Stage the service configuration

Review the example before copying it. On the selected Ubuntu model host:

```bash
install -d -m 700 ~/.config/household-ai ~/.config/systemd/user
install -m 600 deploy/model-service/inference.env.example \
  ~/.config/household-ai/inference.env
install -m 644 deploy/model-service/household-model.service \
  ~/.config/systemd/user/household-model.service
```

Edit `inference.env` so the binary, model path, alias, and runtime settings
exactly match the accepted benchmark. Do not increase context or concurrency as
part of promotion; tune them in a new benchmark run.

`MODEL_CONTEXT` is the total context pool. With independent slots, the
approximate per-request capacity is `MODEL_CONTEXT / MODEL_PARALLEL`; confirm
the exact value reported by the running server. Client configurations must
advertise that per-slot value rather than the total pool.

The conservative KV-cache type is `f16`. Quantized cache types such as `q8_0`
can reduce accelerator-visible memory and may improve throughput on
memory-bandwidth-limited hardware, but they can also change quality or backend
compatibility. Benchmark key and value cache types with the selected model,
longest intended prompt, tool use, concurrent requests, and swap monitoring
before promotion.

Create `~/.config/household-ai/inference-api-keys` with mode `600`. llama.cpp
accepts one key per line, allowing separate revocable credentials for Open
WebUI and coding clients. Generate and transfer keys through a secure local
channel or password manager. Do not put them in Git, command examples, issues,
or benchmark reports.

## 2. Start without enabling at boot

Starting the service changes the host and requires owner approval:

```bash
systemctl --user daemon-reload
systemctl --user start household-model.service
systemctl --user status household-model.service --no-pager
curl --fail http://127.0.0.1:18080/v1/health
```

Use an API key to verify `/v1/models` and one short chat completion. Confirm the
returned model ID equals `MODEL_ALIAS`. Then repeat the relevant quality test,
including a tool-call task for programming models. A process being healthy is
not evidence that its chat template or tool calls work.

## 3. Publish privately through Tailscale

Review the tailnet policy first. Restrict the model API to the intended people
or device group, then expose a dedicated HTTPS port:

```bash
tailscale serve --bg --https=8443 http://127.0.0.1:18080
tailscale serve status
```

From a second Tailscale device, verify:

```text
https://MODEL_HOST.TAILNET_NAME.ts.net:8443/v1/health
```

The endpoint must fail from a device outside the tailnet. Do not configure
router forwarding, a public DNS record, or Tailscale Funnel.

## 4. Connect Open WebUI

Open WebUI can use any OpenAI-compatible endpoint. Set the control plane's
private configuration to:

```dotenv
INFERENCE_API_BASE_URL=https://MODEL_HOST.TAILNET_NAME.ts.net:8443/v1
INFERENCE_NO_PROXY_HOST=MODEL_HOST.TAILNET_NAME.ts.net
INFERENCE_API_KEY=use-the-dedicated-openwebui-key
DEFAULT_MODELS=household-primary
```

`INFERENCE_NO_PROXY_HOST` is the hostname without a scheme, port, or path. It
keeps model traffic on Tailscale instead of sending it through the VPN proxy
reserved for internet search.

Validate the Compose render before restarting anything. After an approved
restart, go to **Admin Settings → Connections → OpenAI**, confirm the URL and
key, and set the provider hint to `llama.cpp`. If model discovery fails, add
the stable alias to the Model IDs filter.

When Open WebUI and the model run on the same Linux host, still verify the
tailnet HTTPS URL from inside the Open WebUI container. This keeps the client
configuration identical when the model later moves to another supported host.

## 5. Connect OpenCode or another coding client

Merge `deploy/model-service/opencode.provider.jsonc` into the user's global
OpenCode configuration, replace the endpoint placeholder, and make its context
limit match the promoted service. Do not replace unrelated providers.

In OpenCode, run `/connect`, choose **Other**, use provider ID `household`, and
enter the dedicated coding-client key. Then select
`household/household-primary` with `/models`.

See [coding clients](coding-clients.md) for OpenClaw, Claude Code, generic
OpenAI-compatible clients, credential handling, and context troubleshooting.

Other clients should use the same HTTPS base URL, stable model alias, and their
own API key when they support one.

## 6. Enable restart recovery

Only after local, remote, chat, and coding tests pass:

```bash
systemctl --user enable household-model.service
```

User services require a persistent user manager to start without an interactive
login. Enabling lingering is an administrative change and requires separate
owner approval:

```bash
loginctl enable-linger "$USER"
```

Reboot in an approved window. Verify the model health, authenticated model
list, Open WebUI response, coding tool call, and `tailscale serve status`.

## Rollback

Keep the old model and service configuration until the promoted model survives
the reboot test. To withdraw the new endpoint without deleting model data:

```bash
systemctl --user disable --now household-model.service
tailscale serve --https=8443 off
```

Restore the previous service and client alias mapping. Never delete weights,
keys, chats, or Open WebUI volumes as part of ordinary rollback.

## Upstream references

- [llama.cpp server documentation](https://github.com/ggml-org/llama.cpp/tree/master/tools/server)
- [Tailscale Serve command](https://tailscale.com/docs/reference/tailscale-cli/serve)
- [Open WebUI OpenAI-compatible connections](https://docs.openwebui.com/getting-started/quick-start/connect-a-provider/starting-with-openai-compatible/)
- [OpenCode providers](https://opencode.ai/docs/providers)
