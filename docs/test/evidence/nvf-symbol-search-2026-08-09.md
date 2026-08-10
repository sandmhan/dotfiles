---
title: NVF Symbol Search and Call Hierarchy Evidence
status: accepted
updated: 2026-08-09
---

# NVF Symbol Search and Call Hierarchy Evidence

## Scope

Correct the effective LSP-buffer keymap collision that caused NVF's buffer-local
signature-help mapping to shadow the configured FzfLua document-symbol picker on
`<leader>ls`. Keep signature help on `<leader>lk`, add a Treesitter-backed
current-buffer symbol fallback on `<leader>fs`, and add incoming/outgoing LSP call
hierarchy on `<leader>lci` and `<leader>lco`.

The shared Sandvim module affects `sandmhan`, `terminalman`, `wslman`, and
`macman`.

## Red-green regression

The Phase 8 runtime validator was extended before the implementation. The red run
built the packaged editor, attached Markdown LSP clients, and failed with the
confirmed effective mapping:

```text
effective <leader>ls is not FzfLua document symbols
buffer = 1
desc = "Signature help"
```

After setting `vim.lsp.mappings.signatureHelp = "<leader>lk"` and removing the
redundant global signature-help mapping, the same packaged runtime check passed.
The permanent runtime harness is `scripts/check-nvf-symbol-search.lua`.

## Runtime coverage

The Phase 8 harness creates a temporary two-file Python project and opens it with
the built `terminalman` NVF package. It verifies:

- basedpyright attaches and advertises document symbols, workspace symbols,
  definitions, references, and call hierarchy;
- `<leader>ls`, `<leader>lw`, `<leader>lr`, `<leader>ld`, `<leader>lci`, and
  `<leader>lco` retain their effective FzfLua mappings after LSP attachment;
- `<leader>lk` is the effective buffer-local signature-help mapping;
- FzfLua exposes Treesitter, document/workspace symbol, and incoming/outgoing
  call providers;
- document symbols include a class, method, and functions;
- workspace symbol search finds a function in a second file after cold indexing;
- Python has a Treesitter parser and locals query for the non-LSP fallback;
- incoming calls for `make_message` include `greet`; and
- outgoing calls for `top_level` include `Greeter` and `greet`.

## Validation

| Command | Result | Notes |
|---|---|---|
| `nixfmt --check home/modules/nvf/lsp.nix home/modules/nvf/keymaps.nix` | passed | Changed Nix modules are formatted. |
| `git diff --check` | passed | No whitespace errors. |
| `bash -n scripts/check-nvf-*.sh` | passed | All NVF shell validators parse. |
| ShellCheck on `scripts/check-nvf-baseline.sh` and `scripts/check-nvf-phase8.sh` with `SC2016` excluded | passed | `SC2016` is intentionally excluded because literal Markdown backticks are single-quoted grep patterns. |
| Statix on the changed Nix modules | passed | No findings. |
| Deadnix on the changed Nix modules | passed | No unused arguments remain. |
| `bash scripts/check-nvf-baseline.sh` through `bash scripts/check-nvf-phase8.sh` | passed | All cumulative NVF phase checks pass. |
| `NVF_PHASE8_REQUIRE_RUNTIME=1 bash scripts/check-nvf-phase8.sh` | passed | Requires the packaged runtime symbol, Treesitter, LSP, and call-hierarchy checks. |
| `nix build --dry-run --option eval-cache false .#homeConfigurations.sandmhan.activationPackage --show-trace` | passed | Main Linux desktop profile evaluates without activation. |
| `nix build --dry-run --option eval-cache false .#homeConfigurations.terminalman.activationPackage --show-trace` | passed | Linux terminal profile evaluates without activation. |
| `nix build --dry-run --option eval-cache false .#homeConfigurations.wslman.activationPackage --show-trace` | passed | WSL profile evaluates without activation. |
| `nix build --dry-run --option eval-cache false .#homeConfigurations.macman.activationPackage --show-trace` | passed | Darwin profile evaluates without activation. |
| `nix build --no-link --option eval-cache false .#checks.x86_64-linux.sandvimExternalConsumer --show-trace` | passed | Portable external-consumer Home Manager package builds. |
| Packaged `nvim --headless "+checkhealth" "+qa!"` | passed | Full health check completed. |
| Packaged scoped `checkhealth vim.lsp`, `checkhealth nvim-treesitter`, and `checkhealth dap` | passed | LSP, Treesitter, and DAP health checks completed. |
| Packaged `:FzfLua` and `:Trouble` command-existence smoke | passed | Symbol-search and outline entry points are registered. |

## Skipped checks

Home Manager activation was intentionally not run. All required no-activation
profile, portability, phase, and packaged runtime validation completed.
