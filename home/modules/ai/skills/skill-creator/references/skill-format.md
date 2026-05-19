# Skill Format Reference

Canonical specification for the SKILL.md format and platform-specific extensions.

---

## SKILL.md Frontmatter

| Field | Required | Type | Notes |
| --- | --- | --- | --- |
| `name` | Yes | string | kebab-case, lowercase, digits, hyphens only; max 64 chars; matches folder name |
| `description` | Yes | string | Primary trigger mechanism; include all "when to use" info; ~100–300 words |

No other YAML fields should appear in frontmatter. Do not add `version`, `tags`, `author`, etc.

### Description quality checklist

- [ ] Describes **what** the skill does
- [ ] Lists **specific user phrases** or **keywords** that should trigger it
- [ ] Covers **concrete scenarios** (not vague topics)
- [ ] Claude Code style: third-person — "This skill should be used when the user wants to..."
- [ ] Does NOT contain "when to use" guidance that belongs in the body

---

## agents/openai.yaml (Codex UI metadata)

Location: `skill-name/agents/openai.yaml`

```yaml
interface:
  display_name: "Human Readable Name"       # Title case, max ~30 chars
  short_description: "Brief description"    # 25–64 chars; shown as chip label
  default_prompt: "Use $skill-name to ..."  # Suggested prompt; must use $skill-name

  # Optional fields (only include if explicitly needed):
  icon_small: "./assets/icon-small.png"     # 64×64 PNG
  icon_large: "./assets/icon-large.png"     # 256×256 PNG
  brand_color: "#3B82F6"                    # hex color for UI accents

dependencies:                               # optional MCP tool requirements
  tools:
    - type: "mcp"
      value: "tool-name"
      description: "What this tool does"
      transport: "streamable_http"
      url: "https://..."

policy:
  allow_implicit_invocation: true           # default true; set false to require explicit trigger
```

**Claude Code behavior:** The `agents/openai.yaml` file is silently ignored. Safe to include.

---

## .claude-plugin/plugin.json (Claude Code plugin registration)

Location: at the **root** of the plugin/repo, not inside individual skills.

```json
{
  "name": "plugin-name",
  "description": "What this plugin provides",
  "author": {
    "name": "Author Name",
    "email": "optional@email.com"
  }
}
```

Claude Code scans the `skills/` directory inside a plugin root and auto-discovers all subdirectories containing `SKILL.md`.

**Codex behavior:** This file is ignored. Safe to include.

---

## Platform Loading Behavior

| Phase | Claude Code | Codex |
| --- | --- | --- |
| Always in context | `name` + `description` frontmatter | Same |
| On skill trigger | Full SKILL.md body | Same |
| On demand | Files in `references/`, `scripts/`, `assets/` | Same |
| Plugin discovery | `skills/` in `.claude-plugin` dir | `~/.codex/skills/` directory |

---

## Directory Structure Conventions

```text
skill-name/
├── SKILL.md                    (required)
├── agents/
│   └── openai.yaml             (recommended for cross-compatibility)
├── references/
│   ├── topic-a.md              (loaded when topic-a is in scope)
│   └── topic-b.md
├── scripts/
│   ├── probe-env.sh            (bash: environment probe)
│   └── probe-env.ps1           (powershell: same, for Windows)
├── assets/
│   └── templates/
│       └── starter.yaml
└── evals/
    └── evals.json              (optional: evaluation test cases)
```

### File type conventions

- `scripts/` — executable code; test before shipping; include contract comment at top
- `references/` — markdown docs; include ToC for files >100 lines; one topic per file
- `assets/` — output files (templates, images, fonts); NOT loaded into context
- `evals/` — test cases; not loaded into context

---

## Progressive Disclosure Patterns

### Pattern 1: Intent Router

```markdown
## Intent Router
- `references/aws.md` — AWS deployment patterns
- `references/gcp.md` — GCP deployment patterns
Load only the file matching the user's chosen provider.
```

### Pattern 2: Conditional details

```markdown
## Creating Documents
Use docx-js. See references/docx-js.md for full API.

For tracked changes: see references/redlining.md
```

**Guidelines:**

- Keep references one level deep from SKILL.md
- For reference files >100 lines, include a table of contents at the top
- Never duplicate information across SKILL.md and a reference file; choose one location

---

## Prompt Engineering Standards

Apply these 7 principles when writing any new skill. They reflect standards from
Anthropic, OpenAI, and academic research on effective LLM prompting.

### 1. Specificity over Generality

Write concrete, specific instructions instead of vague ones.

- ✓ "Run `git diff --staged` to see what's in the index"
- ✗ "Check what's staged"

Use exact command-line syntax, flags, and expected output format.

### 2. Concrete, Diverse Examples

Provide 2–3 realistic, runnable examples per major workflow. Cover happy path,
gotchas, and error recovery.

- Example 1: common case
- Example 2: edge case or gotcha
- Example 3: error recovery

Examples should be copy-paste-ready.

### 3. Step-by-Step Numbered Workflows

Use ordered lists (1, 2, 3) for multi-step procedures. Each step is atomic and verifiable.

```markdown
1. Fetch the latest: `git fetch origin main`
2. Start rebase: `git rebase -i origin/main`
3. Verify: `git log origin/main..HEAD` (should show your commits)
```

### 4. Verification Steps After Actions

Always include a step to verify success after each action.

```markdown
1. Create the file: `touch my-file.txt`
2. Verify: `ls -la my-file.txt` (should list the file)
```

### 5. Explicit Failure Modes

Document common errors and how to recover.

```markdown
If you get "Permission denied":
1. Check permissions: `ls -la <path>`
2. Add write permission: `chmod u+w <path>`
3. Retry the operation
```

### 6. Single Responsibility

Define what the skill covers and what it does NOT cover.

```markdown
This skill covers: creating branches, rebasing, undoing commits
This skill does NOT cover: GitHub PR workflows (see `gh` skill)
```

### 7. Specify Output Format

Always specify what output the agent should expect or produce.

```markdown
The command outputs status like:
  On branch main
  Your branch is ahead by 3 commits

Parse this to extract branch name and commit count.
```

---

See `validation/public-references.md` for full academic references and integration checklist.
