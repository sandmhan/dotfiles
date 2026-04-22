{
  pkgs,
  lib,
  ...
}:
let
  # Path to claude config files relative to this module
  claudeDir = ./claude;
in
{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    # Global settings for Claude Code
    settings = {
      # Permission settings - adjust based on your trust level
      permissions = {
        allow = [
          "Bash(git status:*)"
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "Bash(git branch:*)"
          "Bash(nix flake show:*)"
          "Bash(nix flake metadata:*)"
          "Bash(nix eval:*)"
          "Bash(nix build --dry-run:*)"
          "Bash(nixfmt:*)"
          "Bash(make:*)"
          "Bash(ls:*)"
          "Bash(cat:*)"
          "Bash(head:*)"
          "Bash(tail:*)"
          "Bash(find:*)"
          "Bash(grep:*)"
          "Bash(rg:*)"
          "Read"
          "Write"
          "Edit"
          "Glob"
          "Grep"
          "WebFetch"
          "WebSearch"
        ];
        deny = [ ];
      };

      # Preferred model
      model = "claude-sonnet-4-20250514";

      # Theme
      theme = "dark";
    };

    # Load skills from separate files
    skills = {
      # Comprehensive Nix skills (from nix-agent-skills.zip)
      "nix-bootstrap" = builtins.readFile "${claudeDir}/skills/nix-bootstrap/SKILL.md";
      "nix-darwin" = builtins.readFile "${claudeDir}/skills/nix-darwin/SKILL.md";
      "nix-debug" = builtins.readFile "${claudeDir}/skills/nix-debug/SKILL.md";
      "nix-devshell" = builtins.readFile "${claudeDir}/skills/nix-devshell/SKILL.md";
      "nix-flake" = builtins.readFile "${claudeDir}/skills/nix-flake/SKILL.md";
      "nix-home-manager" = builtins.readFile "${claudeDir}/skills/nix-home-manager/SKILL.md";
      "nix-lang" = builtins.readFile "${claudeDir}/skills/nix-lang/SKILL.md";

      # Custom homelab and best practices skills (extracted from original nix-flake)
      "nix-homelab" = builtins.readFile "${claudeDir}/skills/nix-homelab.md";
      "nix-best-practices" = builtins.readFile "${claudeDir}/skills/nix-best-practices.md";
    };

    # Load rules from separate files
    rules = {
      "nix-conventions" = builtins.readFile "${claudeDir}/rules/nix-conventions.md";
      "homelab" = builtins.readFile "${claudeDir}/rules/homelab.md";
    };
  };
}
