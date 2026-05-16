# Codex provider module.
# Maps shared AI skills/rules from myHome.ai into Codex's file-based config format.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.myHome;
  ai = cfg.ai;

  codexConfigToml = ''
    model = "o3"
    approval_policy = "on-request"
    sandbox_mode = "workspace-write"

    [features]
    web_search = true
    memories = true
  '';

  # Build AGENTS.md by concatenating all rules
  agentsMd = lib.concatStringsSep "\n\n" (lib.attrValues ai.rules);

  # Build home.file entries for Codex skills
  dirSkillFiles = lib.mapAttrs' (
    name: skill:
    lib.nameValuePair ".agents/skills/${name}" {
      source = skill.sourceDir;
      recursive = true;
    }
  ) (lib.filterAttrs (_: s: s.sourceDir != null) ai.skills);

  standaloneSkillFiles = lib.mapAttrs' (
    name: skill:
    lib.nameValuePair ".agents/skills/${name}/SKILL.md" {
      text = skill.content;
    }
  ) (lib.filterAttrs (_: s: s.sourceDir == null) ai.skills);
in
{
  config = lib.mkIf cfg.features.enableCodex {
    home.packages = [ pkgs.codex ];

    xdg.configFile."codex/config.toml".text = codexConfigToml;

    home.file = {
      ".codex/AGENTS.md".text = agentsMd;
    }
    // dirSkillFiles
    // standaloneSkillFiles;
  };
}
