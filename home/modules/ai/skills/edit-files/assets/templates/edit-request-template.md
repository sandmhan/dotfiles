# Edit Request Template

Use this template to shape a file-editing task before making changes.

```text
Task:
- [specific change to make]

Scope:
- Only modify: [files or directories]
- Avoid modifying: [files or directories]

Desired behavior:
- [required outcome]
- [required outcome]

Constraints and invariants:
- Preserve: [behavior, API, formatting rule, architecture boundary]
- Use or prefer: [library, utility, pattern]
- Avoid: [library, pattern, rewrite, unrelated cleanup]

Structured edit choice:
- File format: [JSON / YAML / XML / TOML / code / docs / other]
- Preferred structured path when applicable: [jq / yq / not applicable]

Validation:
- Run: [formatter]
- Run: [lint / typecheck]
- Run: [tests]

Output expectations:
- Summarize files changed
- Explain why the chosen approach is correct
- Note any risks, assumptions, or checks that could not run
```
