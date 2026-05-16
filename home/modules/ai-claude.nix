# Claude Code provider module.
# Maps shared AI skills/rules from myHome.ai into programs.claude-code format.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.myHome;
  ai = cfg.ai;
in
{
  config = lib.mkIf cfg.features.enableClaudeCode {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;

      settings = {
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

        model = "claude-sonnet-4-20250514";
        theme = "dark";
      };

      # Map shared skills: name -> content string
      skills = lib.mapAttrs (_: skill: skill.content) ai.skills;

      # Map shared rules: name -> content string
      rules = ai.rules;
    };
  };
}
