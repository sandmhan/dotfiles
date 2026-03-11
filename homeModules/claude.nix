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
      "nix-flake" = builtins.readFile "${claudeDir}/skills/nix-flake.md";
    };

    # Load rules from separate files
    rules = {
      "nix-conventions" = builtins.readFile "${claudeDir}/rules/nix-conventions.md";
      "homelab" = builtins.readFile "${claudeDir}/rules/homelab.md";
    };
  };
}
