# AI agent overlay for autonomous operation in isolated VMs.
# Merges agent-specific skills/rules into the shared pool and
# overrides tool settings for permissive autonomous operation.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  aiDir = ./ai;
in
{
  # Merge agent-specific skills into the shared pool
  myHome.ai.skills = {
    "homelab-architect" = {
      content = builtins.readFile "${aiDir}/agent-skills/homelab-architect/SKILL.md";
      sourceDir = "${aiDir}/agent-skills/homelab-architect";
    };
    "vm-deployment" = {
      content = builtins.readFile "${aiDir}/agent-skills/vm-deployment/SKILL.md";
      sourceDir = "${aiDir}/agent-skills/vm-deployment";
    };
    "container-management" = {
      content = builtins.readFile "${aiDir}/agent-skills/container-management/SKILL.md";
      sourceDir = "${aiDir}/agent-skills/container-management";
    };
  };

  # Merge agent-specific rules into the shared pool
  myHome.ai.rules = {
    "agent-operating-guidelines" =
      builtins.readFile "${aiDir}/agent-rules/agent-operating-guidelines.md";
  };

  # Additional agent packages
  home.packages = [
    pkgs.curl
  ];

  # Override Claude Code bootstrap settings for autonomous mode
  myHome.ai.claude.settings = lib.mkForce {
    permissions = {
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
      deny = [
        "Bash(rm -rf /:*)"
        "Bash(dd:*)"
        "Bash(mkfs:*)"
        "Bash(fdisk:*)"
        "Bash(parted:*)"
      ];
    };
    dangerouslyAcceptPermissions = true;
    model = "claude-sonnet-4-20250514";
    theme = "dark";
    agent = {
      workspace = "/home/agent/workspace";
      autoSave = true;
      contextWindow = 200000;
    };
  };

  # Override Codex config bootstrap for autonomous mode
  myHome.ai.codex.configToml = lib.mkForce ''
    model = "gpt-5-codex"
    model_reasoning_effort = "medium"
    approval_policy = "never"
    sandbox_mode = "danger-full-access"

    [features]
    web_search = true
    memories = true
    multi_agent = true

    [agents]
    max_threads = 4
    max_depth = 2
  '';

  # Agent workspace directories
  home.file = {
    "workspace/.gitkeep".text = "";
    "workspace/homelab/.gitkeep".text = "";
    "workspace/testing/.gitkeep".text = "";
    "workspace/deployments/.gitkeep".text = "";
    "templates/.gitkeep".text = "";
    "scripts/.gitkeep".text = "";
    "logs/.gitkeep".text = "";
  };

  # PATH setup
  home.sessionVariables = {
    PATH = "$HOME/.local/bin:$PATH";
  };

  # Agent-specific shell aliases for Claude and Codex
  programs.bash.shellAliases = {
    claude-homelab = "cd ~/workspace/homelab && claude --dangerously-accept-permissions";
    claude-testing = "cd ~/workspace/testing && claude --dangerously-accept-permissions";
    claude-deploy = "cd ~/workspace/deployments && claude --dangerously-accept-permissions";
    claude-workspace = "cd ~/workspace && claude --dangerously-accept-permissions";
    agent-claude = "claude --dangerously-accept-permissions";
    codex-homelab = "cd ~/workspace/homelab && codex";
    codex-testing = "cd ~/workspace/testing && codex";
    codex-deploy = "cd ~/workspace/deployments && codex";
    codex-workspace = "cd ~/workspace && codex";
    agent-codex = "codex";
  };

  # Git configuration for agent commits
  programs.git = {
    enable = true;
    settings = {
      user.name = lib.mkForce "Autonomous Agent";
      user.email = lib.mkForce "agent@homelab.local";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      commit.gpgsign = false;
      core.editor = "vim";
    };
  };
}
