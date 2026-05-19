# rg Cheatsheet

## High-value options

- `-n`: Show line numbers.

- `-i`: Case-insensitive search.

- `--glob <GLOB>`: Include or exclude file patterns.

- `--json`: Emit JSON events for machine parsing.

## Common one-liners

1. Fixed-string search

```bash

rg -F 'localhost:5432' .

```

1. Match whole words only

```bash

rg -w 'session' src

```

1. Include hidden files

```bash

rg --hidden --glob '!.git' 'token' .

```

## Input/output patterns

- Input: Pattern with optional path roots, globs, and ignore behavior flags.

- Output: Matched lines (text mode) or structured JSON events (`--json`).

## Troubleshooting quick checks

- If no matches appear, confirm current directory and ignore settings.

- If regex interpretation is wrong, switch to `-F` or escape metacharacters.

- If output is noisy, tighten with globs and explicit root paths.

## When not to use this command

- Do not use `rg` for replacements; pair search output with an editor or transformation tool.
