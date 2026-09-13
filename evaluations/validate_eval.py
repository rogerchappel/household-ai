#!/usr/bin/env python3

import json
import sys
from pathlib import Path


REQUIRED_FIELDS = {"id", "category", "messages", "expectation"}
VALID_ROLES = {"user", "assistant", "system"}


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    identifiers: set[str] = set()

    with path.open(encoding="utf-8") as source:
        for line_number, raw_line in enumerate(source, start=1):
            if not raw_line.strip():
                continue
            try:
                case = json.loads(raw_line)
            except json.JSONDecodeError as exc:
                errors.append(f"line {line_number}: invalid JSON: {exc.msg}")
                continue

            if not isinstance(case, dict):
                errors.append(f"line {line_number}: case must be an object")
                continue

            missing = REQUIRED_FIELDS - case.keys()
            if missing:
                errors.append(
                    f"line {line_number}: missing fields: {', '.join(sorted(missing))}"
                )

            identifier = case.get("id")
            if not isinstance(identifier, str) or not identifier:
                errors.append(f"line {line_number}: id must be a non-empty string")
            elif identifier in identifiers:
                errors.append(f"line {line_number}: duplicate id: {identifier}")
            else:
                identifiers.add(identifier)

            messages = case.get("messages")
            if not isinstance(messages, list) or not messages:
                errors.append(f"line {line_number}: messages must be a non-empty list")
                continue

            for message_number, message in enumerate(messages, start=1):
                if not isinstance(message, dict):
                    errors.append(
                        f"line {line_number}, message {message_number}: must be an object"
                    )
                    continue
                if message.get("role") not in VALID_ROLES:
                    errors.append(
                        f"line {line_number}, message {message_number}: invalid role"
                    )
                if not isinstance(message.get("content"), str) or not message["content"]:
                    errors.append(
                        f"line {line_number}, message {message_number}: content must be non-empty"
                    )

    if not identifiers:
        errors.append("no evaluation cases found")
    return errors


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        "evals/independent-judgment.jsonl"
    )
    errors = validate(path)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    count = sum(1 for line in path.open(encoding="utf-8") if line.strip())
    print(f"validated {count} cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
