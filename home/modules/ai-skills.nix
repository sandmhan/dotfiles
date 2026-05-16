# Provider-agnostic AI skills and rules data module.
# Exposes shared content via myHome.ai.{skills,rules} options that
# tool-specific modules (ai-claude.nix, ai-codex.nix, etc.) consume.
# Also materializes a canonical discovery directory at ~/.local/share/ai/
# for tools not managed through Nix (e.g., pi-mono).
{
  lib,
  config,
  ...
}:
let
  cfg = config.myHome;
  aiDir = ./ai;

  # Build home.file entries for the canonical ~/.local/share/ai/ directory
  canonicalSkillFiles =
    let
      dirSkills = lib.mapAttrs' (
        name: skill:
        lib.nameValuePair ".local/share/ai/skills/${name}" {
          source = skill.sourceDir;
          recursive = true;
        }
      ) (lib.filterAttrs (_: s: s.sourceDir != null) cfg.ai.skills);

      standaloneSkills = lib.mapAttrs' (
        name: skill:
        lib.nameValuePair ".local/share/ai/skills/${name}/SKILL.md" {
          text = skill.content;
        }
      ) (lib.filterAttrs (_: s: s.sourceDir == null) cfg.ai.skills);
    in
    dirSkills // standaloneSkills;

  canonicalRuleFiles = lib.mapAttrs' (
    name: content:
    lib.nameValuePair ".local/share/ai/rules/${name}.md" {
      text = content;
    }
  ) cfg.ai.rules;
in
{
  options.myHome.ai = with lib; {
    skills = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            content = mkOption {
              type = types.str;
              description = "SKILL.md content (markdown with frontmatter)";
            };
            sourceDir = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "Source directory with SKILL.md + references/. Null for standalone skills.";
            };
          };
        }
      );
      default = { };
      description = "Provider-agnostic AI skills keyed by name";
    };

    rules = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Provider-agnostic AI rules (markdown content keyed by name)";
    };
  };

  config = lib.mkIf cfg.features.enableAISkills {
    # Populate shared skills from ai/skills/
    myHome.ai.skills = {
      # Directory-based skills (SKILL.md + references/)
      "nix-bootstrap" = {
        content = builtins.readFile "${aiDir}/skills/nix-bootstrap/SKILL.md";
        sourceDir = "${aiDir}/skills/nix-bootstrap";
      };
      "nix-darwin" = {
        content = builtins.readFile "${aiDir}/skills/nix-darwin/SKILL.md";
        sourceDir = "${aiDir}/skills/nix-darwin";
      };
      "nix-debug" = {
        content = builtins.readFile "${aiDir}/skills/nix-debug/SKILL.md";
        sourceDir = "${aiDir}/skills/nix-debug";
      };
      "nix-devshell" = {
        content = builtins.readFile "${aiDir}/skills/nix-devshell/SKILL.md";
        sourceDir = "${aiDir}/skills/nix-devshell";
      };
      "nix-flake" = {
        content = builtins.readFile "${aiDir}/skills/nix-flake/SKILL.md";
        sourceDir = "${aiDir}/skills/nix-flake";
      };
      "nix-home-manager" = {
        content = builtins.readFile "${aiDir}/skills/nix-home-manager/SKILL.md";
        sourceDir = "${aiDir}/skills/nix-home-manager";
      };
      "nix-lang" = {
        content = builtins.readFile "${aiDir}/skills/nix-lang/SKILL.md";
        sourceDir = "${aiDir}/skills/nix-lang";
      };
      # Standalone skills (single .md, no references/)
      "nix-best-practices" = {
        content = builtins.readFile "${aiDir}/skills/nix-best-practices.md";
      };
      "nix-homelab" = {
        content = builtins.readFile "${aiDir}/skills/nix-homelab.md";
      };
    };

    # Populate shared rules from ai/rules/
    myHome.ai.rules = {
      "nix-conventions" = builtins.readFile "${aiDir}/rules/nix-conventions.md";
      "homelab" = builtins.readFile "${aiDir}/rules/homelab.md";
    };

    # Canonical discovery directory for non-Nix tools
    home.file = canonicalSkillFiles // canonicalRuleFiles;

    # Environment variable for programmatic discovery
    home.sessionVariables = {
      AI_SKILLS_DIR = "$HOME/.local/share/ai";
    };
  };
}
