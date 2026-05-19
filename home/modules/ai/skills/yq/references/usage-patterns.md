# yq Usage Patterns

Common workflows and patterns for using yq with YAML, JSON, XML, and TOML files.

## Format Conversion Workflows

### YAML to JSON Pipeline

```bash
# Convert YAML to JSON
yq -o json config.yml > config.json

# Pretty-print JSON
yq -o json config.yml | jq .

# Compact JSON
yq -o json -c config.yml
```

### JSON to YAML with Roundtrip

When converting formats that support custom tags or folded strings:

```bash
# Standard conversion
yq -o yaml data.json > data.yml

# Preserve YAML structure during processing
yq -Y -o yaml data.json > data.yml
```

### Batch Format Conversion

Convert all YAML files in directory to JSON:

```bash
for file in *.yml; do
  yq -o json "$file" > "${file%.yml}.json"
done
```

## Filtering & Selection

### Extract Specific Fields

Extract multiple fields from objects:

```bash
# Get just name and email from users
yq '.users[] | {name: .name, email: .email}' users.yml

# Extract specific version
yq '.metadata.version' deployment.yml
```

### Filter Arrays by Condition

```bash
# Get active services only
yq '.services[] | select(.enabled == true)' config.yml

# Find user by ID
yq '.users[] | select(.id == 123)' users.yml

# Get all items with priority > 5
yq '.items[] | select(.priority > 5)' items.yml
```

### Combine Multiple Filters

```bash
# Get active services and sort by name
yq '.services[] | select(.enabled == true) | sort_by(.name)' config.yml

# Get unique values from array
yq '.tags | unique' file.yml
```

## In-Place File Editing

### Modify Configuration Files

```bash
# Update version field
yq -i '.version = "2.0.0"' package.yml

# Add new field
yq -i '.author = "Jane Doe"' config.yml

# Remove a field
yq -i 'del(.deprecated)' config.yml

# Create backup before modifying
yq -i '.version = "2.0"' -b '.bak' config.yml
```

### Conditional Modifications

```bash
# Only update if field exists
yq -i 'if .status then .status = "updated" else . end' file.yml

# Add field only if missing
yq -i '.created //= now' file.yml

# Update nested field
yq -i '.database.host = "localhost"' config.yml
```

## Data Transformation

### Restructure Objects

```bash
# Flatten nested structure
yq 'to_entries | map({key: .key, value: .value}) | from_entries' file.yml

# Convert object to array of key-value pairs
yq 'to_entries' config.yml

# Convert array of objects to map
yq 'map({(.id): .}) | add' users.yml
```

### Array Operations

```bash
# Get unique items
yq '.items | unique' file.yml

# Sort array
yq '.items | sort' file.yml

# Sort by field
yq '.users | sort_by(.name)' users.yml

# Reverse array
yq '.items | reverse' file.yml

# Get first/last N items
yq '.items[:5]' file.yml
yq '.items[-3:]' file.yml
```

### String Operations

```bash
# Split and process strings
yq '.tags | split(",") | map(ltrimstr(" "))' file.yml

# Join array with separator
yq '.parts | join("-")' file.yml

# String interpolation
yq '.items[] | "\(.id): \(.name)"' file.yml

# Replace text
yq '.description |= gsub("old"; "new")' file.yml
```

## Multi-File Processing

### Merge Multiple Files

```bash
# Combine multiple YAML files
yq -s 'add' file1.yml file2.yml file3.yml

# Merge into single output
yq -s '.[0] * .[1]' base.yml overrides.yml
```

### Read Multiple Files as Input

```bash
# Process each file in a directory
for file in *.yml; do
  yq '.version' "$file"
done

# Process with xargs
ls *.yml | xargs -I {} yq '.name' {}
```

## XML Processing with xq

```bash
# Extract XML element
xq '.book.author' config.xml

# Convert XML to JSON
xq -o json books.xml

# Convert XML to YAML
xq -o yaml books.xml

# Filter XML elements
xq '.books.book[] | select(.price < 20)' books.xml
```

## TOML Processing with tomlq

```bash
# Extract TOML section
tomlq '.database.host' config.toml

# Convert TOML to JSON
tomlq -o json config.toml

# Modify TOML file
tomlq -i '.version = "1.0.0"' pyproject.toml
```

## Roundtrip Mode for YAML Tags

Preserve YAML-specific features when processing files with custom tags:

```bash
# Process while preserving custom tags
yq -Y -i '.description |= split("\n")' file.yml

# Read and write with tag preservation
yq -Y . file.yml > output.yml
```

## Error Handling & Validation

```bash
# Check if required fields exist
yq 'if has("required_field") then . else error("Missing required field") end' file.yml

# Provide default values
yq '.timeout //= 30' config.yml

# Type checking
yq 'if (.port | type) == "number" then . else error("port must be number") end' config.yml
```

## Performance Considerations

For large files:

```bash
# Use compact output for streaming
yq -c '.[]' large-file.yml

# Process with slurp for aggregate operations
yq -s 'map(.id) | unique | length' *.yml

# Limit output with head
yq '.[]' large-file.yml | head -20
```
