# Household assistants and access control

Open WebUI calls reusable assistant configurations **Models**. A workspace model
is a preset around one base inference model: it can add a name, system prompt,
parameters, knowledge, tools, and access rules without loading another copy of
the model into memory.

The labels below use “assistant” for the household-facing preset and “base
model” for the promoted inference endpoint.

## A small two-person starting set

Begin with fewer assistants than you think you need:

| Assistant | Purpose | Suggested access |
| --- | --- | --- |
| Home Assistant | General questions, household admin, cited web research | Both household members |
| Learning Guide | Homeschool planning and age-appropriate explanations | Both household members |
| Shopping Research | Compare products, prices, and sources without inventing current facts | Both household members |
| Developer | Coding and technical work with a larger context budget | Developer only |
| Private Journal | Personal reflection with no shared knowledge or memory | Its owner only |
| Relationship Reflection | Structured communication prompts, not diagnosis or crisis care | Create separate private or mutually shared versions deliberately |

Do not treat a system prompt as a confidentiality boundary. Privacy comes from
resource access control, separate accounts, and careful knowledge/tool grants.

## Create an assistant

As an administrator or permitted workspace editor:

1. Open **Workspace > Models > Create**.
2. Choose the promoted base model.
3. Give the preset a stable ID, human name, short description, and starter
   suggestions.
4. Add the assistant's system prompt in this model editor.
5. Enable only the capabilities it needs and attach only its intended knowledge,
   tools, or skills.
6. Set visibility to **Private**, then grant Read access to an individual or a
   sharing group.
7. Test it while signed in as a normal user.

The **System Prompt** field in an individual chat's controls affects that chat
or request. It is useful for experiments, but it is not the centrally managed
prompt for every user. Edit the durable assistant prompt in **Workspace >
Models**, then edit the relevant model preset.

Prompts are behavioural instructions, not hard enforcement. A model may still
ignore them. Permissions must be enforced by Open WebUI and by any upstream
service, not by asking the model to keep something secret.

## Base-model access is required

An Open WebUI assistant is a wrapper, so a user must also be allowed to use its
base model. For a curated household interface:

1. make the generic base model available to intended users;
2. hide it from the ordinary model selector; and
3. expose named assistant presets with the intended access grants.

Hiding is interface curation, not an authorization boundary. Never place private
instructions or knowledge on the generic base model. Keep those resources on
private assistant presets.

## Least-privilege group design

Open WebUI permissions are additive: global defaults and every group grant are
combined, and there is no overriding Deny. Start restrictive and grant upward.

A manageable two-person layout is:

- **Household** — a sharing group containing both members; no extra feature
  permissions.
- **P-Web-Search** — a permission-only group granting web search; hidden from
  ordinary sharing menus.
- **Developer** — a sharing group containing only the developer.
- Direct user grants — for personal assistants and knowledge that should not be
  shared even with a broad household group.

Configure the baseline under **Admin Panel > Users > Groups > Default
Permissions**. Create and edit groups under **Admin Panel > Users > Groups**.
Keep permission groups separate from sharing groups so access is easy to audit
and revoke.

Example resource matrix:

| Resource | Visibility | Grant |
| --- | --- | --- |
| Generic base model | Available, but hidden | Intended household users |
| Home Assistant preset | Private | Household: Read |
| Developer preset | Private | Developer: Read |
| Shared household knowledge | Private | Household: Read; admin: Write |
| Personal knowledge | Private | Owner: Read; owner/admin as deliberate Write |
| Search tool/capability | Private or feature-gated | P-Web-Search |

Use **Preview Access** on a normal user and on each group after every change.
Test with the normal account; an administrator sees everything and cannot prove
that isolation works.

## Knowledge and tool access

Attaching knowledge or a tool to an assistant does not bypass its own access
rules. The user needs Read access to:

1. the assistant preset;
2. its base model;
3. every attached private knowledge base; and
4. every attached private tool.

If an attached knowledge base appears unavailable:

- confirm the assistant and knowledge base each grant the user or one of their
  groups Read access;
- confirm the knowledge base is attached to the assistant preset;
- use Preview Access to inspect effective grants;
- check whether Native Function Calling is enabled globally—when it is, the
  model must invoke the knowledge tool rather than receiving automatic
  retrieval;
- verify the base model handles tool calls reliably; and
- start a fresh chat after changing bindings or permissions.

For web search, configure the provider at the admin level, grant the Web Search
feature, then enable Web Search on each assistant. A prompt saying “you can
search” does not provide a search capability. Verify with a time-sensitive query
whose answer includes inspectable citations.

## Private-assistant checklist

Before adding sensitive content:

1. use a unique normal-user account for each person;
2. keep the assistant, knowledge, tools, and skills Private;
3. grant access directly to the intended person, not the Household group;
4. disable personal memory on assistants that should not receive it;
5. test visibility and use from both normal accounts;
6. export or back up configuration only to encrypted storage; and
7. remember that instance administrators and host operators remain trusted.

Open WebUI RBAC governs the application interface and API. External model
providers, proxies, storage, backups, host administrators, and logs need their
own least-privilege and retention controls.

## Acceptance test

Use two non-admin test accounts and confirm:

- shared assistants are visible and complete a normal prompt;
- each private assistant is visible only to its intended owner;
- shared knowledge can be retrieved with a source;
- personal knowledge cannot be discovered or attached by the other account;
- enabled web search returns a current result with citations;
- tools unavailable to a user are not exposed through an attached assistant;
  and
- neither user can edit shared prompts, models, tools, or knowledge unless they
  were deliberately granted Write access.

Open WebUI changes its interface over time. These paths target the v0.11 model
and RBAC interface; verify them against the
[official Models documentation](https://docs.openwebui.com/features/workspace/models/)
and [official RBAC documentation](https://docs.openwebui.com/features/authentication-access/rbac/).
