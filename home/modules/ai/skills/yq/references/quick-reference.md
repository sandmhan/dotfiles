# yq Quick Reference

Essential yq commands, flags, and options for common data processing tasks.

## Command Structure

| Command | Purpose |
| --- | --- |
| `yq` | Process YAML files (main tool) |
| `xq` | Process XML files (XML variant) |
| `tomlq` | Process TOML files (TOML variant) |

All support identical jq filtering syntax and flags.

## Common Flags

| Flag | Purpose | Example |
| --- | --- | --- |
| `-y`, `--yaml-output` | Output in YAML format | `yq -y . file.yml` |
| `-Y`, `--roundtrip` | Preserve YAML tags and styles | `yq -Y . file.yml` |
| `-i`, `--in-place` | Modify file directly | `yq -i '.foo = "bar"' file.yml` |
| `-r`, `--raw-output` | Output raw strings (not quoted) | `yq -r '.name' file.yml` |
| `-s`, `--slurp` | Read entire input as array | `yq -s . file.yml` |
| `-c`, `--compact-output` | Compact JSON output | `yq -c . file.yml` |
| `-o json` | Output JSON format | `yq -o json file.yml` |
| `-o yaml` | Output YAML format | `yq -o yaml file.json` |
| `--arg key value` | Pass string variable to filter | `yq '.name = $name' --arg name "John" file.yml` |
| `--slurpfile var file` | Pass file contents as variable | `yq '.users += $new' --slurpfile new users.yml file.yml` |

## Format Conversion

| Task | Command |
| --- | --- |
| YAML to JSON | `yq -o json file.yml > file.json` |
| JSON to YAML | `yq -o yaml file.json > file.yml` |
| YAML to JSON (compact) | `yq -o json -c file.yml` |
| Preserve YAML structure | `yq -Y . file.yml > output.yml` |

## Basic Filtering

| Task | Command |
| --- | --- |
| Extract top-level key | `yq .foo file.yml` |
| Extract nested field | `yq .foo.bar.baz file.yml` |
| Extract array element | `yq '.[0]' file.yml` |
| Extract all array elements | `yq '.[]' file.yml` |
| Get keys of object | `yq 'keys' file.yml` |
| Get values of object | `yq '.[]' file.yml` |
| Check if key exists | `yq 'has("foo")' file.yml` |
| Get length | `yq 'length' file.yml` |

## Selection & Filtering

| Task | Command |
| --- | --- |
| Filter array by condition | `yq '.[] \| select(.status == "active")' file.yml` |
| Filter by type | `yq '.[] \| select(type == "string")' file.yml` |
| Filter by presence | `yq '.[] \| select(.email)' file.yml` |
| Get first matching | `yq 'first(.[] \| select(.id == 5))' file.yml` |

## Modification

| Task | Command |
| --- | --- |
| Set field value | `yq '.foo = "bar"' file.yml` |
| Update nested field | `yq '.foo.bar = 42' file.yml` |
| Add array element | `yq '.items += ["new"]' file.yml` |
| Increment counter | `yq '.count = (.count + 1)' file.yml` |
| Merge objects | `yq '. + {"new": "field"}' file.yml` |
| Delete field | `yq 'del(.foo)' file.yml` |
| Modify in-place | `yq -i '.foo = "bar"' file.yml` |

## String Operations

| Task | Command |
| --- | --- |
| Split string | `yq '.text \| split(",")' file.yml` |
| Join array | `yq '.items \| join(",")' file.yml` |
| Convert to lowercase | `yq '.name \| ascii_downcase' file.yml` |
| Convert to uppercase | `yq '.name \| ascii_upcase' file.yml` |
| String interpolation | `yq '"Hello \(.name)"' file.yml` |

## Output Formats

| Task | Command |
| --- | --- |
| Pretty JSON | `yq -o json . file.yml` |
| Compact JSON | `yq -o json -c . file.yml` |
| YAML output | `yq -o yaml . file.json` |
| Raw text (strip quotes) | `yq -r . file.yml` |
| Tab-separated values | `yq -r '.[] \| [.id, .name] \| @tsv' file.yml` |
| CSV output | `yq -r '.[] \| [.id, .name] \| @csv' file.yml` |
