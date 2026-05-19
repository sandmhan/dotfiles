# yq Examples & Recipes

Practical examples and real-world recipes for common yq workflows.

## Configuration Management

### Update Application Configuration

Before:

```yaml
# app-config.yml
app:
  name: MyApp
  version: 1.0.0
  database:
    host: localhost
    port: 5432
  debug: true
```

Update version and disable debug:

```bash
yq -i '.app.version = "1.1.0" | .app.debug = false' app-config.yml
```

After:

```yaml
app:
  name: MyApp
  version: 1.1.0
  database:
    host: localhost
    port: 5432
  debug: false
```

### Merge Environment-Specific Configuration

Base configuration:

```yaml
# config-base.yml
database:
  host: localhost
  port: 5432
  ssl: false
cache:
  ttl: 300
```

Environment override:

```yaml
# config-prod.yml
database:
  host: prod.db.example.com
  port: 5432
  ssl: true
cache:
  ttl: 3600
```

Merge with override taking precedence:

```bash
yq -s '.[0] * .[1]' config-base.yml config-prod.yml > config-final.yml
```

Result:

```yaml
database:
  host: prod.db.example.com
  port: 5432
  ssl: true
cache:
  ttl: 3600
```

## Data Extraction & Reporting

### Extract User Data from Directory

Input file with users:

```yaml
# users.yml
users:
  - id: 1
    name: Alice
    email: alice@example.com
    role: admin
    active: true
  - id: 2
    name: Bob
    email: bob@example.com
    role: user
    active: false
  - id: 3
    name: Carol
    email: carol@example.com
    role: user
    active: true
```

Extract active users only:

```bash
yq -r '.users[] | select(.active == true) | "\(.name): \(.email)"' users.yml
```

Output:

```text
Alice: alice@example.com
Carol: carol@example.com
```

### Generate CSV from YAML

```bash
# Extract as CSV (with header)
echo "id,name,email,role"
yq -r '.users[] | [.id, .name, .email, .role] | @csv' users.yml
```

Output:

```text
id,name,email,role
1,"Alice","alice@example.com","admin"
2,"Bob","bob@example.com","user"
3,"Carol","carol@example.com","user"
```

## Kubernetes Manifest Processing

### Extract Image Names from Deployment

```yaml
# deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  template:
    spec:
      containers:
        - name: app
          image: myrepo/app:v1.2.3
        - name: sidecar
          image: myrepo/sidecar:v1.0.0
```

Get all container images:

```bash
yq '.spec.template.spec.containers[] | .image' deployment.yml
```

Output:

```text
myrepo/app:v1.2.3
myrepo/sidecar:v1.0.0
```

### Update Image Versions in Batch

```bash
# Update all image tags to v2.0.0
yq -i '.spec.template.spec.containers[] |= .image |= sub(":.*"; ":v2.0.0")' deployment.yml
```

## Package Manager Configuration

### Update Python Package Version

Before:

```yaml
# pyproject.toml
[project]
name = "myapp"
version = "1.0.0"

[project.optional-dependencies]
dev = ["pytest==7.0.0", "black==22.0.0"]
```

Update version:

```bash
tomlq -i '.project.version = "1.1.0"' pyproject.toml
```

### Extract Dependencies

```bash
# Get all dev dependencies
tomlq '.project.optional-dependencies.dev[]' pyproject.toml
```

## Docker Compose Processing

### Extract Service Names

```yaml
# docker-compose.yml
version: '3.8'
services:
  db:
    image: postgres:13
    ports:
      - "5432:5432"
  web:
    image: myapp:latest
    depends_on:
      - db
  cache:
    image: redis:6
```

Get all service names:

```bash
yq '.services | keys[]' docker-compose.yml
```

Output:

```text
db
web
cache
```

### Update Service Image Versions

```bash
# Update postgres version
yq -i '.services.db.image = "postgres:14"' docker-compose.yml
```

## JSON to YAML Migration

Original JSON file:

```json
{
  "app": {
    "name": "MyApp",
    "version": "1.0.0",
    "ports": [8080, 8443],
    "features": {
      "api": true,
      "ui": true
    }
  }
}
```

Convert and pretty-print:

```bash
yq -o yaml myapp.json > myapp.yml
```

Result:

```yaml
app:
  name: MyApp
  version: 1.0.0
  ports:
    - 8080
    - 8443
  features:
    api: true
    ui: true
```

## Error Handling Patterns

### Validate Required Fields

Script to check configuration:

```bash
# Ensure required fields exist
yq 'if has("database") and .database | has("host") then . else error("Missing database.host") end' config.yml
```

### Provide Default Values

```bash
# Set defaults if missing
yq '.database.timeout //= 30 | .database.pool_size //= 10' config.yml
```

### Type Validation

```bash
# Ensure port is a number
yq 'if (.port | type) != "number" then error("Port must be a number") else . end' config.yml
```

## Batch Processing

### Update All YAML Files in Directory

Create a script to update all configuration files:

```bash
#!/bin/bash
for file in *.yml; do
  yq -i '.version = "2.0.0"' "$file"
  echo "Updated $file"
done
```

### Process Multiple Files and Report

```bash
# Extract and report data from multiple files
for file in */config.yml; do
  echo "=== $file ==="
  yq '.app.version' "$file"
done
```

### Merge Secrets from Multiple Sources

```bash
# Combine secrets from different files
yq -s '.[0] * .[1] * .[2]' secrets-base.yml secrets-${ENV}.yml secrets-local.yml
```

## Debugging & Troubleshooting

### Pretty-Print to Inspect Structure

```bash
# Pretty-print JSON to see structure
yq -o json config.yml | jq .

# Pretty-print YAML
yq . config.yml
```

### Check Filter Syntax

```bash
# Test filter without writing
yq '.foo.bar | select(.id > 10)' input.yml

# Use -o json for different output format
yq -o json '.[]' input.yml
```

### Preserve YAML Formatting

For files with special YAML formatting (folded strings, custom tags):

```bash
# Process with roundtrip mode
yq -Y -i '.description |= split("\n")' file.yml
```
