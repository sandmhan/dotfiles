# Claude Code Configuration for Autonomous Agent VM
# Enables broader permissions for safe autonomous operation in isolated environment
{
  pkgs,
  lib,
  ...
}:
let
  # Path to claude config files relative to this module
  claudeDir = ./claude;

  # Claude Code installation script as a derivation
  claude-code-installer = pkgs.writeShellScriptBin "claude-code-install" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if claude is already installed
    if command -v claude &> /dev/null; then
      echo "Claude Code is already installed"
      exit 0
    fi

    # Download and install Claude Code
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install | sh

    # Add to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    echo "Claude Code installation complete"
  '';
in
{
  # Install Claude Code
  home.packages = [
    claude-code-installer
    pkgs.curl  # Required for installation
  ];

  # Set up Claude Code configuration directory and workspace
  home.file = {
    # Claude configuration
    ".claude/skills" = {
      source = "${claudeDir}/skills";
      recursive = true;
    };

    ".claude/rules" = {
      source = "${claudeDir}/rules";
      recursive = true;
    };

    # Agent-specific Claude Code settings
    ".claude/settings.json" = {
      text = builtins.toJSON {
        # Autonomous agent permissions - safe in isolated VM
        permissions = {
          # Allow all common operations for autonomous development
          allow = [
            # Git operations
            "Bash(git:*)"

            # Nix operations
            "Bash(nix:*)"
            "Bash(nixos-rebuild:*)"
            "Bash(nixfmt:*)"

            # Container operations
            "Bash(docker:*)"
            "Bash(docker-compose:*)"

            # Build and deployment
            "Bash(make:*)"
            "Bash(cargo:*)"
            "Bash(npm:*)"
            "Bash(yarn:*)"
            "Bash(go:*)"

            # File operations
            "Bash(ls:*)"
            "Bash(cat:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(find:*)"
            "Bash(grep:*)"
            "Bash(rg:*)"
            "Bash(fd:*)"
            "Bash(tree:*)"
            "Bash(mkdir:*)"
            "Bash(cp:*)"
            "Bash(mv:*)"
            "Bash(rm:*)"
            "Bash(chmod:*)"
            "Bash(chown:*)"

            # Network and system info
            "Bash(curl:*)"
            "Bash(wget:*)"
            "Bash(ping:*)"
            "Bash(nslookup:*)"
            "Bash(dig:*)"
            "Bash(ss:*)"
            "Bash(netstat:*)"
            "Bash(ps:*)"
            "Bash(top:*)"
            "Bash(htop:*)"
            "Bash(df:*)"
            "Bash(free:*)"
            "Bash(uptime:*)"

            # Text processing
            "Bash(sed:*)"
            "Bash(awk:*)"
            "Bash(jq:*)"
            "Bash(yq:*)"

            # Archive operations
            "Bash(tar:*)"
            "Bash(zip:*)"
            "Bash(unzip:*)"

            # All file tools
            "Read"
            "Write"
            "Edit"
            "Glob"
            "Grep"
            "WebFetch"
            "WebSearch"
          ];

          # Only block truly dangerous operations
          deny = [
            "Bash(rm -rf /:*)"
            "Bash(dd:*)"
            "Bash(mkfs:*)"
            "Bash(fdisk:*)"
            "Bash(parted:*)"
          ];
        };

        # Default to accepting permissions for autonomous operation
        dangerouslyAcceptPermissions = true;

        # Preferred model
        model = "claude-sonnet-4-20250514";

        # Theme
        theme = "dark";

        # Agent-specific configuration
        agent = {
          workspace = "/home/agent/workspace";
          autoSave = true;
          contextWindow = 200000;
        };
      };
    };

    # Agent-specific skills for Claude Code
    ".claude/skills/homelab-architect.md".text = ''
# Homelab Infrastructure Architect

## Role
You are an autonomous infrastructure architect for a Nix-based homelab. Your primary goal is to design, implement, and deploy reliable services through declarative configuration.

## Core Responsibilities
- Design service architectures that follow Nix/NixOS best practices
- Create modular, reusable configuration templates
- Test configurations locally before deployment
- Document architectural decisions and deployment procedures
- Maintain security and reliability standards

## Workflow Patterns
1. **Service Design**: Analyze requirements and design appropriate architecture
2. **Local Development**: Create and test configurations in isolated containers
3. **Validation**: Use nix build --dry-run and nixos-rebuild --dry-run
4. **Documentation**: Create comprehensive deployment and maintenance docs
5. **Deployment**: Deploy to staging/production VMs via nixos-rebuild

## Key Principles
- Prefer native NixOS services over containers when available
- Use OCI containers only when native packages are unavailable
- Always include health checks and monitoring configuration
- Design for backup and disaster recovery from day one
- Follow the principle of least privilege for service access

## Available Tools
- Full Nix toolchain for configuration development
- Docker for service testing and prototyping
- SSH access to deploy to remote systems
- Network debugging tools for connectivity testing
- Monitoring tools for service validation

When given a task, break it down into concrete steps and execute them systematically.
    '';

    ".claude/skills/vm-deployment.md".text = ''
# VM Deployment Automation

## Purpose
Automate the provisioning and deployment of new VMs for homelab services.

## Capabilities
- Generate VMA images for Proxmox deployment
- Create service-specific VM configurations
- Automate remote deployment via nixos-rebuild
- Validate deployments and service health
- Manage VM lifecycle (create, update, destroy)

## Deployment Patterns

### New Service VM
1. Create hosts/<service>/default.nix based on hosts/server template
2. Add service-specific systemModules
3. Update flake.nix with new configuration
4. Build and test configuration locally
5. Generate VMA image for Proxmox deployment
6. Deploy and validate service operation

### Service Update
1. Modify configuration in workspace
2. Test changes with nix build --dry-run
3. Deploy to VM with nixos-rebuild switch --target-host
4. Validate service operation and rollback if needed

## Best Practices
- Always test configurations before deployment
- Use staging VMs for major changes
- Maintain deployment documentation
- Monitor resource usage and performance
- Plan for backup and recovery procedures
    '';

    ".claude/skills/container-management.md".text = ''
# Container Management for Homelab Services

## Purpose
Manage OCI containers for services without native NixOS packages.

## Container Strategy
- Use containers only when native NixOS services are unavailable
- Prefer official images from trusted sources
- Implement proper networking and security isolation
- Ensure persistent storage for stateful services
- Include health checks and monitoring

## Configuration Patterns

### OCI Container Service
```nix
virtualisation.oci-containers.containers.myservice = {
  image = "myservice:latest";
  ports = [ "8080:8080" ];
  volumes = [ "/var/lib/myservice:/data" ];
  environment = {
    CONFIG_FILE = "/data/config.yaml";
  };
  extraOptions = [
    "--health-cmd=curl -f http://localhost:8080/health"
    "--health-interval=30s"
    "--health-retries=3"
  ];
};
```

### Service Integration
- Configure systemd dependencies
- Set up reverse proxy with nginx
- Implement backup strategies for container data
- Monitor resource usage and logs

## Management Tasks
- Container lifecycle management
- Image updates and security patching
- Data backup and recovery
- Performance monitoring and optimization
    '';

    ".claude/rules/agent-operating-guidelines.md".text = ''
# Autonomous Agent Operating Guidelines

## Safety Boundaries
- You are operating in an isolated VM environment designed for safe autonomous operation
- Network access is restricted to essential services only
- All operations are logged and monitored
- Resource usage is constrained to prevent system impact

## Autonomous Operation Principles
1. **Test First**: Always validate configurations before deployment
2. **Document Changes**: Maintain clear documentation of all modifications
3. **Incremental Progress**: Make small, testable changes rather than large rewrites
4. **Error Handling**: Implement proper error handling and rollback procedures
5. **Security Awareness**: Maintain security best practices even in isolated environment

## Development Workflow
1. Work in ~/workspace with organized project structure
2. Use git for version control and change tracking
3. Test locally using containers before VM deployment
4. Validate with nix build --dry-run and flake checks
5. Deploy incrementally with validation at each step

## Communication Guidelines
- Provide clear status updates on task progress
- Explain architectural decisions and trade-offs
- Flag any issues or blockers immediately
- Request clarification when requirements are ambiguous

## Resource Management
- Monitor system resources during development
- Clean up temporary files and build artifacts
- Use efficient development practices
- Respect VM resource limitations

Remember: Your goal is to advance homelab infrastructure development safely and efficiently while maintaining high quality and security standards.
    '';

    # Create agent workspace directories
    "workspace/.gitkeep".text = "";
    "workspace/homelab/.gitkeep".text = "";
    "workspace/testing/.gitkeep".text = "";
    "workspace/deployments/.gitkeep".text = "";
    "templates/.gitkeep".text = "";
    "scripts/.gitkeep".text = "";
    "logs/.gitkeep".text = "";
  };

  # Add PATH setup for Claude Code
  home.sessionVariables = {
    PATH = "$HOME/.local/bin:$PATH";
  };

  # Auto-install Claude Code on first login
  home.activation.installClaude = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${claude-code-installer}/bin/claude-code-install
  '';

  # Agent-specific shell aliases for Claude integration
  programs.bash.shellAliases = {
    claude-homelab = "cd ~/workspace/homelab && claude --dangerously-accept-permissions";
    claude-testing = "cd ~/workspace/testing && claude --dangerously-accept-permissions";
    claude-deploy = "cd ~/workspace/deployments && claude --dangerously-accept-permissions";
    claude-workspace = "cd ~/workspace && claude --dangerously-accept-permissions";
    agent-claude = "claude --dangerously-accept-permissions";
  };

  # Git configuration for agent commits
  programs.git = {
    enable = true;
    userName = lib.mkForce "Autonomous Agent";
    userEmail = lib.mkForce "agent@homelab.local";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      commit.gpgsign = false;
      core.editor = "vim";
    };
  };
}