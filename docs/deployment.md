# Deploy the version 0.1 control plane

This deployment provides the multi-user web interface and private web search.
It connects to an OpenAI-compatible inference server selected and verified by
the benchmark workflow.

Before configuring the control plane, use the
[model promotion workflow](model-promotion.md) to turn the accepted benchmark
configuration into a persistent, authenticated, tailnet-only endpoint.

The supported v0.1 control-plane host is Ubuntu Linux. Open WebUI is bound only
to host loopback and may be shared privately with Tailscale Serve. No router port
forwarding or public ingress is required.

## Architecture

```text
Household browser
      |
      | private HTTPS through Tailscale Serve
      v
Open WebUI on 127.0.0.1:3000
      |                         |
      | tailnet HTTPS API        | search and page loading
      v                         v
Promoted model service      Gluetun VPN
                                |
                                v
                              SearXNG
```

SearXNG shares Gluetun's network namespace, so its outbound searches fail closed
when the VPN is unavailable. Open WebUI also uses Gluetun's internal HTTP proxy
for loading result pages. Local inference and container-to-container addresses
are excluded from that proxy.

## Prerequisites

- a supported Ubuntu host with Docker and Docker Compose;
- a promoted OpenAI-compatible inference endpoint and dedicated Open WebUI key;
- a WireGuard-capable VPN account supported by Gluetun;
- Tailscale installed and connected when private remote access is required; and
- a verified backup before replacing an existing chat deployment.

Version 0.1 has verified the VPN path with Surfshark WireGuard. Other Gluetun
providers require their own variables and are not yet part of the tested path.

## Prepare private configuration

Copy the example and restrict it before adding real values:

```bash
cp .env.example .env
chmod 600 .env
```

Generate independent random values for `WEBUI_SECRET_KEY`, `SEARXNG_SECRET`, and
the local inference API key. Obtain the WireGuard private key and address from
the VPN provider's manual configuration. Never use an ordinary account password
as a WireGuard key, and never paste the completed file into an issue or chat.

Set `INFERENCE_API_BASE_URL` to the promoted model's tailnet-only HTTPS endpoint.
This remains stable whether the model is on the control-plane host or another
supported device. Require a dedicated API key and verify the endpoint from
inside the Open WebUI container before starting the control plane.

## Validate before starting

From the repository root, use the Compose command available on the host:

```bash
docker compose --env-file .env -f deploy/compose.yml config --quiet
```

Older installations may provide `docker-compose` as a standalone command. A
successful render checks the file and required variables but does not prove that
the VPN, inference server, or search providers are reachable.

Review the rendered configuration for unexpected published ports. The only host
port in the template should be `127.0.0.1:3000` for Open WebUI.

## Start and verify

Starting services changes the host and requires owner approval:

```bash
docker compose --env-file .env -f deploy/compose.yml up -d
docker compose --env-file .env -f deploy/compose.yml ps
curl --fail http://127.0.0.1:3000/api/config
```

Create the intended administrator and household accounts through Open WebUI.
After onboarding, disable further sign-ups in the Admin UI. Open WebUI persists
administrative settings in its database, and persisted values take precedence
over later environment-file changes.

Test an ordinary completion before enabling web search. Then ask for current
information and verify that the response contains sources rather than an
unsupported claim that a search occurred.

## Verify private search egress

Check the containers without printing their environment:

```bash
docker inspect household-ai-search-vpn household-ai-search \
  --format '{{.Name}} {{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{end}}'
```

Compare the VPN exit address reported inside Gluetun with an address reported by
the host. They should differ. Treat both addresses as private diagnostic data;
do not paste them into issues or committed logs.

Stop the VPN container temporarily during an approved maintenance window and
confirm that search fails instead of using the host connection. Restore it
immediately after the check.

## Private HTTPS with Tailscale

Once local access works, review the tailnet access policy and enable Tailscale
Serve for the loopback service:

```bash
tailscale serve --bg 3000
tailscale serve status
```

Tailscale may require the owner to enable HTTPS through a browser confirmation.
Use Serve, not Funnel: Funnel would make the service publicly reachable.

Set `WEBUI_URL` to the resulting private HTTPS URL before configuring OAuth or
other integrations that depend on callback URLs.

## Restart behaviour

The containers use `restart: unless-stopped`. Confirm that Docker and Tailscale
start at boot, reboot during an approved window, and repeat the local API, login,
inference, search, and Tailscale checks. Background Tailscale Serve configuration
is designed to resume after daemon and host restarts.

## Backup and rollback

The `household-ai-webui-data` volume contains accounts, chats, agent settings,
and other persistent WebUI data. Back it up before upgrades or replacement and
test restoration on an isolated volume.

To stop the new stack without deleting its volumes:

```bash
docker compose --env-file .env -f deploy/compose.yml down
```

Do not add `--volumes` during ordinary rollback. Restore the previous service
and Tailscale configuration according to the plan recorded before deployment.
