# Starter assistant prompts

These generic prompts are starting points for Open WebUI workspace models. They
contain no household names, locations, relationships, routines, or private
knowledge.

## Recommended starting set

Create these two shared assistants first:

- [Household Assistant](core/household-assistant.md) for everyday questions,
  planning, administration, and careful use of available tools.
- [Research & Shopping](core/research-and-shopping.md) for current, cited
  comparisons without affiliate influence or invented prices.

Add optional assistants only when someone wants their narrower behaviour:

- [Technical Assistant](optional/technical-assistant.md)
- [Personal Reflection](optional/personal-reflection.md)
- [Communication Coach](optional/communication-coach.md)
- [Lifestyle & Wellbeing Coach](optional/lifestyle-wellbeing.md)

There is intentionally no dedicated learning or homeschooling assistant in the
starter pack. Education preferences are household-specific and can be layered
privately onto the Household Assistant later.

## Use in Open WebUI

1. Create or edit a workspace model.
2. Select the promoted base model.
3. Copy the complete contents of one prompt file into its **System Prompt**.
4. Attach only the tools and knowledge named in the intended access plan.
5. Keep the preset Private and grant it to the intended user or group.
6. Test it from a non-admin account before adding personal information.

The prompts refer to capabilities conditionally. Text saying “when web search
is available” does not enable search; configure and grant the capability in
Open WebUI separately.

Open WebUI expands supported variables such as `{{ USER_NAME }}` and
`{{ CURRENT_DATE }}` at request time. Do not add unsupported placeholders or
put secrets into a system prompt.

## Customise privately

Keep public role instructions separate from private context:

- system prompt: reusable behaviour and safety boundaries;
- model settings: temperature, context, tools, and capability bindings;
- private knowledge: household documents and durable reference material; and
- user memory or chat: personal preferences that the user deliberately shares.

Avoid encoding household membership, health history, relationship history,
addresses, credentials, or financial details into an exported model preset.

## Evaluate

The synthetic cases in `evals/assistant-prompts.jsonl` exercise common failure
modes across the starter pack. Capture each assistant separately:

```bash
python3 evaluations/run_eval.py \
  --endpoint http://127.0.0.1:8080 \
  --model candidate-name \
  --label household-assistant \
  --cases evals/assistant-prompts.jsonl \
  --system-prompt prompts/core/household-assistant.md
```

Not every case applies equally to every assistant. Score relevant cases against
their recorded expectations and add narrower tests before trusting a prompt for
sensitive or consequential use.
