---
name: skill-creator
description: >
  Guide for creating, updating, and improving skills that extend LLM agent capabilities
  across platforms. Use when the user wants to create a new skill from scratch, update or
  optimize an existing skill, write a SKILL.md, improve a skill description, understand
  skill structure and progressive disclosure, or make a skill work across multiple agents.
---

# Skill Creator

Guidance for building effective skills — modular, self-contained folders that extend
an LLM agent's capabilities with specialized knowledge, workflows, and tools.

## Core Principles

### Concise is Key

The context window is shared. Only add context the agent doesn't already have. Challenge
every piece of information: "Does the agent really need this?" and "Does this paragraph
justify its token cost?" Prefer concise examples over verbose explanations.

### Set Appropriate Degrees of Freedom

| Freedom level | When to use | How |
| --- | --- | --- |
| High | Multiple valid approaches, context-dependent | Text-based instructions |
| Medium | Preferred pattern, some variation OK | Pseudocode or parameterized scripts |
| Low | Fragile operations, consistency critical | Specific scripts, few parameters |

### Anatomy of a Skill

```text
skill-name/
├── SKILL.md (required)             — frontmatter + instructions
├── agents/
│   └── openai.yaml (recommended)  — Codex UI metadata
└── Bundled Resources (optional)
    ├── scripts/      — Executable code (deterministic, repeatable tasks)
    ├── references/   — Documentation loaded into context on demand
    └── assets/       — Templates, images, boilerplate (used in output, not loaded)
```

### Progressive Disclosure (3-Level Loading)

1. **Frontmatter** (`name` + `description`) — Always in context (~100 words)
2. **SKILL.md body** — When skill triggers (<5k words, ideally <500 lines)
3. **Bundled resources** — As needed (unlimited; scripts can run without loading)

Keep SKILL.md body to essentials. Move detailed docs to `references/`. Always link
references from SKILL.md and describe clearly when to load each file.

---

## SKILL.md Format

### Frontmatter

```yaml
---
name: my-skill          # kebab-case, lowercase, <64 chars
description: >          # primary trigger mechanism — be comprehensive
  Detailed description of what the skill does and when to use it.
  Include all "when to use" information HERE (not in the body).
  The body only loads after triggering.
---
```

**Only `name` and `description` in frontmatter.** No other YAML fields.

### Description Writing

The description is how the agent decides whether to use the skill. Include:

- What the skill does
- Specific triggers / keywords / user phrases
- Concrete scenarios

**Claude agents:** Use third-person — "This skill should be used when the user wants to..."
**OpenAI agents:** Either first or third person works; specificity matters most.

### Body

Write instructions in imperative/infinitive form. Never second-person ("You should...").
Do not include "When to Use This Skill" sections in the body — that content belongs in the description.

---

## Platform Compatibility

Both Claude-based and OpenAI-based agents use the same SKILL.md format. The differences are additive:

| Feature | Claude | OpenAI |
| --- | --- | --- |
| Core format | `SKILL.md` with YAML frontmatter | Same |
| UI metadata | Not required | `agents/openai.yaml` |
| Plugin registration | `.claude-plugin/plugin.json` at plugin root | Not applicable |
| Skill discovery | Via plugin `skills/` directory | Via the OpenAI skills directory |
| Additional plugin dirs | `commands/`, `agents/`, `hooks/` | Not applicable |
| System skills | Not applicable | `.system/` prefix (protected) |

**For cross-compatible skills:** Include `agents/openai.yaml` and ensure SKILL.md works for both. The `agents/openai.yaml` is silently ignored by Claude-based agents.

### agents/openai.yaml (OpenAI agent metadata)

```yaml
interface:
  display_name: "Human-Readable Name"          # Title case, shown in Codex UI
  short_description: "Brief 25-64 char desc"   # Shown as chip/tag
  default_prompt: "Use $skill-name to..."       # Suggested prompt using $skill-name
```

Optional fields: `icon_small`, `icon_large`, `brand_color`. See `references/skill-format.md`.

### Claude Plugin Structure (when publishing as a Claude plugin)

```text
my-plugin/
├── .claude-plugin/
│   └── plugin.json      # {"name": "...", "description": "...", "author": {...}}
├── skills/
│   └── my-skill/
│       └── SKILL.md
├── commands/            # optional: slash commands
└── agents/              # optional: sub-agents
```

---

## Skill Creation Process

### Step 1: Understand with Concrete Examples

Identify:

- What will users ask that should trigger this skill?
- What does a successful outcome look like?
- What would the agent struggle with without this skill?

### Step 2: Plan Bundled Resources

For each concrete example, identify what reusable resource would help:

- **Code rewritten each time** → `scripts/` file
- **Schema/docs looked up each time** → `references/` file
- **Boilerplate copied each time** → `assets/templates/` file

### Step 3: Initialize the Skill

Create the directory structure manually:

```bash
mkdir -p my-skill/{agents,references,scripts,assets}
touch my-skill/SKILL.md my-skill/agents/openai.yaml
```

### Step 4: Build Resources First

Implement `scripts/`, `references/`, and `assets/` before writing SKILL.md. For scripts,
test them by running to verify correctness. Resource files should be self-contained — avoid
requiring context from SKILL.md to understand them.

### Step 5: Write SKILL.md

Start with frontmatter, then body:

1. Intent Router — which reference file to load for which request type
2. Quick reference — the 80% case inline
3. Patterns / workflow — step-by-step for common tasks
4. Safety matrix — destructive commands and required guardrails
5. Resource index — what each script/asset does and its calling contract

### Step 6: Validate and Iterate

Check:

- [ ] YAML frontmatter is valid (`name` and `description` present, no extra fields)
- [ ] `agents/openai.yaml` exists and has `display_name`, `short_description`, `default_prompt`
- [ ] No platform-specific agent names in the body (use "the agent")
- [ ] Body is under 500 lines
- [ ] All referenced files in Intent Router actually exist
- [ ] Destructive operations have explicit guardrails

Use the skill on real tasks; iterate based on what the agent struggled with.

### Step 7: Lint and Validate

Run automated linting:

```bash
bash linting/lint-skill.sh skills/<name>
```

Fix all FAIL items before committing. Address WARN items where practical.

Then run qualitative validation:

```bash
bash validation/validate-skill.sh skills/<name>
```

Load `validation/rubric.md` and score each criterion using the `skill-validation` skill.
Target: zero linting FAILs, all V01–V07 at PASS or WARN, V08 at PASS.

---

## Naming Conventions

- Lowercase, digits, hyphens only; kebab-case; under 64 characters
- Prefer verb-led for action skills: `skill-creator`, `gh-address-comments`
- Namespace by tool when helpful: `gh-*`, `linear-*`, `notion-*`
- Skill folder name must match the `name` frontmatter field

---

## What NOT to Include

Do not create extraneous files: `README.md`, `INSTALLATION_GUIDE.md`, `QUICK_REFERENCE.md`,
`CHANGELOG.md`. The skill exists for the agent, not for humans. Only include files that
directly support the agent's execution of the skill.

---

## Anti-Patterns — What NOT to Do

### 1. Platform-Specific Language

❌ **Bad:** Platform-specific language like "in this agent, use this syntax" or "this agent does X differently"
✅ **Good:** Use "the agent" or omit platform references entirely

### 2. Absolute Paths in Scripts

❌ **Bad:** `export PATH="/Users/alice/my-tools:$PATH"`
✅ **Good:** `export PATH="<path-to-my-tools>:$PATH"` or prompt user for PATH setup

### 3. Extra Frontmatter Fields

❌ **Bad:** `---\nname: foo\ndescription: bar\nicon: pizza\n---`
✅ **Good:** `---\nname: foo\ndescription: bar\n---` (only `name` and `description`)

### 4. Dangling References

❌ **Bad:** Mentioning scripts, references, or assets that don't exist
✅ **Good:** Every file mentioned in Intent Router or instructions actually exists

### 5. Putting Auxiliary Docs in Skill Directory

❌ **Bad:** `my-skill/IMPLEMENTATION.md`, `my-skill/CHANGELOG.md`
✅ **Good:** Keep only `SKILL.md`, `agents/`, `scripts/`, `references/`, `assets/`

### 6. Inconsistent Intent Router

❌ **Bad:** Skill mentions loading references that aren't mapped in Intent Router
✅ **Good:** Intent Router lists every reference file and when to load it

---

## References

- `references/skill-format.md` — canonical field definitions, platform differences, openai.yaml spec
- `validation/public-references.md` — Anthropic/OpenAI/academic prompt engineering standards;
  load when designing new skills or scoring V08 in validation
