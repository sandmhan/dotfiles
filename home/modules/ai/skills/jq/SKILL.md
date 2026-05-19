---
name: jq
description: Query and transform JSON data. Use when the agent needs to search, filter, or transform data efficiently.
---

# Jq

Query and transform JSON data

## Quick Start

1. Verify `jq` is available: `jq --version` or `man jq`
2. Establish the command surface: `man jq` or `jq --help`
3. Start with basic usage: `jq [options] [input]`

## Intent Router

- `references/install-and-setup.md` — Installing jq
- `references/cheatsheet.md` — Common options and patterns
- `references/advanced-usage.md` — Advanced techniques
- `references/troubleshooting.md` — Common errors and solutions

## Core Workflow

1. Verify jq is available: `jq --version`
2. Test with sample data first
3. Validate output before batch processing
4. Document exact commands for reproducibility

## Quick Command Reference

```bash
jq --version                       # Check version
jq --help                          # Show help
jq [options] [input]               # Basic usage
man jq                             # Full manual
```

## Safety Notes

| Area | Guardrail |
| --- | --- |
| **Input validation** | Verify input data format before processing. |
| **Output handling** | Validate output structure. |
| **Large files** | Test with smaller samples first. |

## Source Policy

- Treat installed behavior and man page as truth.

## Resource Index

- `scripts/install.sh` — Install on macOS or Linux.
- `scripts/install.ps1` — Install on Windows or any platform.
