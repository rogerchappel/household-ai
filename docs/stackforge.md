# StackForge scaffold record

The repository baseline was reconciled with StackForge's `oss-cli` profile on
2026-09-14. The source scaffold was generated from StackForge commit
`fa5c5fc` and customised for Household AI.

StackForge does not yet have an infrastructure-toolkit profile. The `oss-cli`
profile was therefore used as the nearest repository-governance baseline, not
as a declaration that Household AI is an npm package.

## Adopted from the scaffold

- contribution and community conduct guidance;
- a security-reporting policy;
- a pull-request template;
- changelog and roadmap conventions; and
- a documentation index.

The existing project-specific `README.md`, `AGENTS.md`, and validation script
were retained because they contain stricter privacy, benchmark-integrity, and
remote-host safety requirements.

## Deliberately excluded

- `package.json` and npm packaging metadata, because the repository is not a
  Node package;
- ReleaseBox configuration and npm release workflows;
- the generic validation script, which duplicates the repository's stronger
  validator;
- the generated `docs/PRD.md`, which duplicated the version 0.1 scope; and
- the generated MIT licence, pending an explicit maintainer licence decision.

Dependabot and CI templates are also deferred until the repository's actual
dependency and test surfaces are stable enough to configure them accurately.

## Regeneration boundary

Generate into a new temporary directory and compare the result. Do not run
StackForge with `--force` against this repository: that would overwrite
project-specific safety documentation and could introduce irrelevant release
automation.

