# Roadmap

This roadmap describes intended direction rather than a delivery promise. New
platforms should be promoted to supported status only after repeatable testing
on real hardware.

## Now: prove version 0.1

- Validate the Apple Silicon and Ubuntu Linux inventory workflows.
- Exercise benchmark and evaluation runners from a clean checkout.
- Make the two-host recommendation report reproducible.
- Test the deployment template without using data from a private household.
- Turn the installer skill into a dependable step-by-step setup path.

## Next: make it approachable

- Add preflight checks and clearer recovery guidance.
- Publish a small, anonymised benchmark-results schema and comparison table.
- Add smoke tests for Open WebUI, model serving, search, restart, and backup.
- Improve guidance for private agents, shared agents, knowledge bases, and
  least-privilege access.
- Document integration with coding clients that use OpenAI-compatible APIs.

## Later: extend the household

- Add tested support for additional Linux GPU configurations.
- Evaluate native Windows support only when it can be maintained without
  weakening the initial workflows; otherwise document Linux as the supported
  path for repurposed Windows hardware.
- Integrate with an open home-automation platform such as Home Assistant.
- Explore local speech capture, text-to-speech, wake words, and room devices.
- Add narrowly scoped household tools and skills with clear permissions.

## Not planned for version 0.1

- A hosted cloud service.
- Silent modification of SSH, firewall, VPN, authentication, or operating-system
  settings.
- Automatic execution of model-generated commands.
- Support claims based only on vendor specifications or synthetic estimates.

