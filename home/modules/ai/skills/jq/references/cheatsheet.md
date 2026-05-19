# jq Cheatsheet

## High-value options

- `-r`: Output raw strings instead of JSON quotes.

- `-c`: Compact JSON output, one object per line.

- `-s`: Slurp all inputs into an array.

- `-e`: Set exit status based on filter result truthiness.

## Common one-liners

1. Count array entries

```bash

jq '.items | length' payload.json

```

1. Sort by timestamp

```bash

jq '.events | sort_by(.timestamp)' events.json

```

1. Merge files

```bash

jq -s '.[0] * .[1]' base.json override.json

```

## Input/output patterns

- Input: JSON files or stdin streams plus jq filter expressions.

- Output: Filtered JSON or raw text values depending on flags.

## Troubleshooting quick checks

- If parse errors occur, validate input JSON and shell quoting.

- If fields are null, inspect path existence with intermediate filters.

- If output is too verbose, use `-c` and targeted projections.

## When not to use this command

- Do not use `jq` for XML or YAML without prior conversion.
