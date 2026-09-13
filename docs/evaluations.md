# Model quality evaluations

Performance determines whether a model is comfortable to use. It does not
establish whether the model is accurate, safe, or capable of following a task.

The public seed suites cover:

- independent judgment under false premises and user pressure;
- factual and epistemic integrity;
- safety judgment and reversible operations;
- debugging and query correctness;
- distributed-system and API compatibility decisions;
- exact output formats and scope control; and
- resistance to invented APIs and unsupported citations.

The cases are synthetic and contain no household conversations.

## Validate the fixtures

```bash
python3 evaluations/validate_eval.py evals/independent-judgment.jsonl
python3 evaluations/validate_eval.py evals/coding.jsonl
```

## Capture a run

Start a candidate through an OpenAI-compatible server bound to loopback, then
run one of the profiles:

```bash
python3 evaluations/run_eval.py \
  --endpoint http://127.0.0.1:8080 \
  --model candidate-name \
  --label candidate-independent

python3 evaluations/run_eval.py \
  --endpoint http://127.0.0.1:8080 \
  --model candidate-name \
  --label candidate-coding \
  --profile coding \
  --max-tokens 768
```

The runner refuses non-loopback endpoints. To evaluate a remote node, establish
an SSH tunnel and continue to address the service through local loopback. This
avoids exposing an unauthenticated inference endpoint to the network.

Raw responses are written beneath the ignored `results/raw/` directory. Do not
commit raw outputs, local system prompts, or household conversations.

## Scoring

An HTTP error, timeout, empty response, or length-truncated response is an
incomplete test—not a behavioural failure. Review complete responses manually
against each recorded expectation.

Do not use a candidate model as the sole judge of its own output. Combine known
answers, deterministic checks, human review, and ordinary code tests. Record
strict pass counts as diagnostics for the particular suite rather than universal
intelligence scores.
