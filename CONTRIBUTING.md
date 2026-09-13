# Contributing

Thanks for helping improve Household AI.

The project is intended to make private, local AI practical for an entire
household. Contributions should keep setup understandable for non-technical
owners while preserving reproducibility for people operating the machines.

## Before opening an issue

- Search existing issues and discussions.
- Confirm the problem is within the current support scope.
- Remove hostnames, IP addresses, usernames, email addresses, credentials,
  private prompts, chats, knowledge-base contents, and unredacted logs.
- Include the smallest reproducible example and the observed result.

Feature requests should explain the household use case, affected hardware or
runtime, likely risks, and why the existing workflow does not cover it.

## Pull requests

Pull requests should:

- focus on one reviewable intent;
- use a branch and Conventional Commits;
- include proportionate tests or verification;
- update documentation when behaviour changes;
- avoid unrelated formatting or dependency churn; and
- use sanitised fixtures instead of data from a real household deployment.

Do not broaden the supported hardware or operating-system matrix based only on
theoretical compatibility. Include repeatable test evidence from real hardware.

## Verification

Run the repository validation before requesting review:

```bash
bash scripts/validate-repository.sh
```

For benchmark or deployment changes, also document the exact targeted command
you ran and any verification that could not be performed locally.

## Review pack

Meaningful changes should include:

```md
## Review Pack
Repo:
Branch:
PR:
Task:
Status: done / blocked / needs review
Summary:
Commits:
Files changed:
Verification:
Risk level:
Rollback plan:
Human decision needed:
Next recommended task:
```

