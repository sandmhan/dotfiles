# System Prompt Considerations

## Direction

The base system prompt should stay general and lean. It should describe how the agent should operate, not enumerate project-specific documentation paths, topic indexes, or domain-specific procedures.

## Desired base prompt qualities

- General across repositories and use cases.
- Focused on operating principles rather than explicit instructions for one domain.
- Encourages discovering authoritative local context before acting.
- Encourages tool-based verification instead of assumptions.
- Requires explicit approval for destructive, irreversible, or infrastructure-mutating actions.
- Keeps responses concise and clear about files, commands, and verification.

## Avoid in the base system prompt

- Hardcoded documentation indexes.
- Repo-specific paths.
- Homelab-specific instructions.
- Package-specific workflow maps.
- Long operational procedures.
- Detailed tool usage policies that belong to extensions or skills.

## Better homes for explicit knowledge

| Concern | Better location |
|---|---|
| Personal coding preferences | Global `AGENTS.md` |
| Repo conventions | Repo `AGENTS.md` / `CLAUDE.md` |
| Homelab topology and safety | Dotfiles-local homelab extension and docs |
| Nix option discovery | Structured Nix diagnostic tools |
| Pi development docs | Search/read tools or a pi-development skill |
| Long procedures | Skills, prompt templates, or repo docs |
| Subagent behavior | Subagent markdown prompts |

## Proposed philosophy

The base prompt should establish a general operating contract:

1. Discover relevant context.
2. Prefer authoritative local sources over assumptions.
3. Use available tools to inspect and verify.
4. Keep output concise.
5. Ask before risky actions.

Explicit routing should be handled by tools, skills, project context, and extensions rather than being embedded directly in the base system prompt.

## Implication for homelab work

Homelab behavior should not be baked into the global system prompt. Instead:

- Global diagnostics can remain available as tools.
- Dotfiles-local extensions can provide homelab context, inventory, safety rules, and mutation gates.
- Mode-specific prompt additions should be short, dynamic, and state-focused, such as the current mode and mutation status.

Example of acceptable dynamic context:

```text
Current mode: homelab-readonly. Infrastructure mutation tools are disabled.
```

Example of context to avoid in the base prompt:

```text
For Proxmox, read docs/infrastructure-registry.md, docs/vm-deployment-lessons.md, and docs/rca/... before running qm commands.
```

The latter belongs in a homelab extension, skill, or project-local instructions.

## Subagent notes

Subagents can have different appended role prompts, but they should follow the same principle:

- Define role, scope, and expected output shape.
- Avoid embedding long documentation indexes.
- Prefer giving subagents discovery tools and scoped instructions.

A subagent should be specialized by role and tools, not by stuffing large amounts of static reference material into its prompt.
