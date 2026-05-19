---
name: rg
description: Fast regex search with recursive directory support. Use when the agent needs to search, filter, or transform data efficiently.
---

# Rg

Fast regex search with recursive directory support

## Quick Start

1. Verify `rg` is available: `rg --version` or `man rg`
2. Establish the command surface: `man rg` or `rg --help`
3. Start with basic usage: `rg [options] [input]`

## Intent Router

- `references/install-and-setup.md` — Installing rg
- `references/cheatsheet.md` — Common options and patterns
- `references/advanced-usage.md` — Advanced techniques
- `references/troubleshooting.md` — Common errors and solutions

## Core Workflow

1. Verify rg is available: `rg --version`
2. Test with sample data first
3. Validate output before batch processing
4. Document exact commands for reproducibility

## Quick Command Reference

```bash
rg --version                       # Check version
rg --help                          # Show help
rg [options] [input]               # Basic usage
man rg                             # Full manual
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
