# Security Policy

## Supported versions

Household AI does not yet publish versioned releases. The latest `main` branch
is the only version considered for security fixes during this early stage.

The repository contains reference tooling and configuration, not a managed
service. Operators remain responsible for reviewing changes and protecting
their own hosts, credentials, networks, model data, chats, and knowledge bases.

## Reporting a vulnerability

Do not report suspected vulnerabilities in public issues, pull requests, or
discussions. Use GitHub private vulnerability reporting for this repository.
If that path is unavailable, ask through a public project channel for a private
contact method without including exploit details or sensitive information.

A useful report includes:

- a clear description of the issue;
- the affected files, versions, workflows, or configuration;
- safe reproduction steps or an attack scenario;
- the potential impact; and
- a suggested mitigation, if known.

Good-faith reports are reviewed as maintainer capacity permits. The project
does not currently promise response or remediation times.

## Scope

In scope:

- insecure defaults shipped by Household AI;
- credential or private-data exposure caused by repository tooling;
- unsafe remote-execution behaviour in the installer workflow; and
- vulnerabilities in project-maintained automation or configuration.

Out of scope:

- vulnerabilities in unmodified third-party models or applications;
- general setup and support questions; and
- weaknesses caused by configurations that contradict the documented safety
  boundaries.

Coordinate disclosure with the maintainers before publishing vulnerability
details.
