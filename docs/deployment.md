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

Create the intended administrator account through Open WebUI. The first account
on a fresh instance becomes the administrator. Onboard ordinary household
accounts only after private HTTPS access works.

Open WebUI persists administrative settings in its database, and persisted
values take precedence over later environment-file changes.

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

## Onboard household members

Give each person their own account rather than sharing the administrator login.
Keep administrator access for maintainers; normal household use should happen
through the `User` role and the resource grants described in
[Household assistants and access control](assistants-and-access.md).

For a small trusted household:

1. Connect the person's device to the tailnet and open the private HTTPS Open
   WebUI address.
2. As the administrator, temporarily enable **New Sign Ups** under **Settings >
   Admin > Authentication**. Keep the default new-user role as `pending`.
3. Let the person create their own account. Do not create or exchange a shared
   household password.
4. In **Admin Panel > Users**, approve the account as a normal `User`, add its
   intended groups, and grant access to the base model and assistant presets.
5. Disable **New Sign Ups** again.
6. Sign in on the person's device and verify the experience as that user. An
   administrator account cannot prove that model, knowledge, and tool isolation
   works.

Do not leave registration open merely because the login page is tailnet-only.
Use strong, unique passwords and preserve the Open WebUI data volume in the
encrypted backup process.

### Add it to a phone home screen

The private site can be installed as a home-screen web app, giving household
members an app-like icon and launch experience without publishing it to an app
store.

On iPhone or iPad with Safari:

1. Open the private HTTPS Open WebUI address in Safari.
2. Tap **Share**, then **Add to Home Screen**.
3. Enable **Open as Web App** and tap **Add**.

With Chrome on iPhone or iPad, open the address, tap **Share**, choose **Add to
Home Screen**, confirm the name, and tap **Add**. Depending on the site and
browser version, the shortcut may open as a web app or in the browser.

Always save the Tailscale HTTPS address, not the loopback or raw HTTP address.
The device must remain connected to the tailnet. HTTPS is also required for
secure browser capabilities such as microphone access; the user must still
grant microphone permission when prompted.

See the current [Open WebUI account setup](https://docs.openwebui.com/getting-started/quick-start/),
[Apple web-app instructions](https://support.apple.com/guide/iphone/iphea86e5236/ios),
and [Chrome iOS shortcut instructions](https://support.google.com/chrome/answer/15085120?co=GENIE.Platform%3DiOS&hl=en)
if the interface changes.

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
