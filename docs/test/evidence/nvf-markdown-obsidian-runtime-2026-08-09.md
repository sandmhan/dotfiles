---
title: NVF Markdown and Obsidian Runtime Evidence
status: accepted
updated: 2026-08-09
---

# NVF Markdown and Obsidian Runtime Evidence

Phase 10 splits documentation and Nix language ownership, makes Markdown lint policy explicit, adds Obsidian attachment/template workflows, and exports a hermetic Markdown runtime flake check.

## TDD evidence

The initial `bash scripts/check-nvf-phase10.sh` run failed because the documentation/Nix pack leaves, focused modules, render-markdown Blink completion, Obsidian workflows, runtime assets, and documentation did not exist. After the first implementation, the runtime fixture exposed a real OFM lint incompatibility: markdownlint MD025 treated frontmatter `title` plus a document H1 as multiple top-level headings. Sandvim now supplies a base MD025 `front_matter_title: ""` policy while allowing repository- and vault-local markdownlint configuration to override it.

## Validation results

| Command | Result | Notes |
|---|---|---|
| `bash scripts/check-nvf-baseline.sh` and `bash scripts/check-nvf-phase2.sh` through `bash scripts/check-nvf-phase10.sh` | Passed | Includes pack schema/compatibility, import ownership, effective Markdown options, keymap uniqueness, docs synchronization, and runtime command checks. |
| `nix build --no-link --no-write-lock-file .#checks.x86_64-linux.{sandvimExternalConsumer,sandvimMinimalConsumer,sandvimMinimalRuntime,sandvimMarkdownRuntime,sandvimJavaRuntime,sandvimStartupProfile}` | Passed | Every exported Sandvim check built directly. |
| `nix build --dry-run --no-link --no-write-lock-file .#homeConfigurations.<profile>.activationPackage --show-trace` | Passed | Passed for `sandmhan`, `terminalman`, `wslman`, and `macman`; no profile was activated. |
| `nix build --dry-run --no-link --no-write-lock-file .#packages.aarch64-darwin.sandvimStandard .#packages.aarch64-darwin.sandvimFull --show-trace` | Passed | Darwin evaluates with `pngpaste` and without Linux-only clipboard dependencies. |
| Closure checks for `xclip` in Linux `sandvimStandard` and `pngpaste` in the Darwin package derivation | Passed | Paste-image helpers are carried by exported standalone Sandvim packages, not only Home Manager generations. |
| `nix flake show --no-write-lock-file` | Passed | The new `sandvimMarkdownRuntime` check is exported. |
| Packaged full Sandvim `nvim --headless -n -i NONE -c 'qa!'` | Passed | Clean startup output. |
| Packaged full Sandvim `+checkhealth` and scoped `checkhealth render-markdown obsidian conform vim.lsp nvim-treesitter` | Passed | No error markers were present. |
| `nixfmt --check flake.nix home/modules/nvf/*.nix` | Passed | Nix formatting is clean. |
| `statix check flake.nix` and `statix check home/modules/nvf` | Passed | No Statix findings. |
| `deadnix --fail` on every changed Nix file | Passed | A whole-directory Deadnix run still reports pre-existing unused `pkgs` arguments in unchanged modules; changed files are clean. |
| Bash syntax, ShellCheck, and `git diff --cached --check` | Passed | Includes the new Phase 10 script and modified baseline/phase scripts. |

The standalone paste-helper closure checks were reproduced with:

```bash
linux_package=$(nix build --no-link --no-write-lock-file --print-out-paths .#packages.x86_64-linux.sandvimStandard)
nix-store -qR "$linux_package" | grep -F -- '-xclip-'

darwin_drv=$(nix path-info --derivation --no-write-lock-file .#packages.aarch64-darwin.sandvimStandard)
nix-store -qR "$darwin_drv" | grep -F -- '-pngpaste-'
```

The repository-wide `nix flake check` was not used because the known unrelated `agent-sandbox` output still lacks `codexPkgs`. All six Sandvim checks were built directly instead.

## Runtime coverage

The `sandvimMarkdownRuntime` check uses a minimal external consumer with only documentation and notes enabled. Its isolated fixture includes YAML frontmatter, a frontmatter title plus H1, GFM tasks and tables, Obsidian wikilinks and embeds, an Obsidian callout/comment/block ID, a footnote, and Mermaid.

The harness verifies:

- packaged `mdformat` formatting through Conform while preserving OFM/GFM constructs;
- packaged `markdownlint-cli2` execution using Sandvim's base config with zero errors through both the CLI and the configured nvim-lint path;
- Markdown and `markdown_inline` Treesitter parsers;
- MarkdownPreview, render-markdown, and Obsidian command registration;
- render/preview and new Obsidian keymaps;
- Linux `wl-paste` and `xclip` availability on the wrapped Neovim PATH;
- functional Obsidian checkbox toggling;
- configured Harper, markdown-oxide, and obsidian-ls attachment without a duplicate nvim-navic owner;
- the `NVF_MARKDOWN_RUNTIME_OK` sentinel under a bounded timeout.

No activation, deployment, or push was performed.
