{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.myHome;
  claudeDir = ../../homeModules/claude;
in
{
  # Claude Code configuration
  programs.claude-code = lib.mkIf cfg.features.enableClaudeCode {
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

    skills = {
      "nix-bootstrap" = builtins.readFile "${claudeDir}/skills/nix-bootstrap/SKILL.md";
      "nix-darwin" = builtins.readFile "${claudeDir}/skills/nix-darwin/SKILL.md";
      "nix-debug" = builtins.readFile "${claudeDir}/skills/nix-debug/SKILL.md";
      "nix-devshell" = builtins.readFile "${claudeDir}/skills/nix-devshell/SKILL.md";
      "nix-flake" = builtins.readFile "${claudeDir}/skills/nix-flake/SKILL.md";
      "nix-home-manager" = builtins.readFile "${claudeDir}/skills/nix-home-manager/SKILL.md";
      "nix-lang" = builtins.readFile "${claudeDir}/skills/nix-lang/SKILL.md";
      "nix-homelab" = builtins.readFile "${claudeDir}/skills/nix-homelab.md";
      "nix-best-practices" = builtins.readFile "${claudeDir}/skills/nix-best-practices.md";
    };

    rules = {
      "nix-conventions" = builtins.readFile "${claudeDir}/rules/nix-conventions.md";
      "homelab" = builtins.readFile "${claudeDir}/rules/homelab.md";
    };
  };

  # Development packages
  home.packages =
    with pkgs;
    lib.optionals cfg.profiles.enableDevelopment [
      typst
      git
    ]
    ++ lib.optionals cfg.features.enableContainerTools [
      docker-compose
      podman-compose
    ]
    ++ lib.optionals (cfg.profiles.enableVirtualization && cfg.platform.enableLinuxSpecific) [
      qemu
      libvirt
    ];

  # Development environment variables
  home.sessionVariables = lib.mkIf cfg.profiles.enableDevelopment {
    EDITOR = "nvim";
    BROWSER = if cfg.platform.enableLinuxSpecific then "firefox" else "open";
  };
}
