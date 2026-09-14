# Back up and restore Open WebUI

Open WebUI stores accounts, chats, configuration, authentication state, agent
definitions, and knowledge metadata in its persistent volume. Treat every
backup as highly sensitive household data.

The supplied scripts are deliberately inert unless passed `--execute`. Review
the resolved container, volume, archive, and destination before running them.

## Create a consistent backup

Choose an absolute destination on encrypted storage with enough free space.
The script briefly stops Open WebUI, archives its volume, verifies the archive
and expected database, then restores the container to its previous running
state:

```bash
scripts/backup-openwebui.sh --execute /absolute/encrypted/backup/root
```

The defaults match `deploy/compose.yml`. Override them only for a reviewed
deployment with different names:

```bash
HOUSEHOLD_WEBUI_CONTAINER=your-container \
HOUSEHOLD_WEBUI_VOLUME=your-volume \
  scripts/backup-openwebui.sh --execute /absolute/backup/root
```

A local archive protects against a bad upgrade but not disk failure, theft, or
host loss. Copy the completed directory to separate encrypted storage and
verify `SHA256SUMS` there. Do not commit, upload, or attach the archive to an
issue.

## Rehearse an isolated restore

Restoration always targets a new Docker volume and refuses to overwrite an
existing one:

```bash
scripts/restore-openwebui.sh --execute \
  /absolute/backup/openwebui-volume.tar.zst \
  household-ai-restore-test
```

By default the script uses the image of the existing Open WebUI container as a
local extraction helper. On a different recovery host, first obtain a reviewed
image and pass its pinned reference or image ID as the fourth argument.

The script does not attach the restored volume to production. Inspect it with a
temporary container on an unused loopback port, verify login and representative
data, then remove that test container. A production cutover is a separate,
approved change to the Compose volume mapping.

## Acceptance gate

A backup is not considered recoverable until:

1. archive and checksum verification pass;
2. the expected Open WebUI database is present;
3. the original service returns healthy;
4. a copy exists on separate encrypted storage; and
5. an isolated restoration rehearsal succeeds.

Record the date, application image, archive checksum, recovery host, outcome,
and operator without including credentials or private data.

## Limitations

Version 0.1 backs up the Open WebUI state that cannot be reconstructed from the
repository. Model files, downloaded container images, search caches, and VPN
state are intentionally excluded. Back up private deployment configuration and
secrets separately using an encrypted secret-management or system-backup tool.
