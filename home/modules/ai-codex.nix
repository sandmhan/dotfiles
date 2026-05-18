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

  standaloneSkillTexts = lib.mapAttrs (
    name: skill: pkgs.writeText "codex-skill-${name}.md" skill.content
  ) (lib.filterAttrs (_: s: s.sourceDir == null) ai.skills);

  materializeSkillsScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: skill:
      if skill.sourceDir != null then
        ''
          rm -rf "$HOME/.codex/skills/${name}"
          mkdir -p "$HOME/.codex/skills/${name}"
          cp -R --no-preserve=mode,ownership ${lib.escapeShellArg "${skill.sourceDir}/."} "$HOME/.codex/skills/${name}/"
        ''
      else
        ''
          rm -rf "$HOME/.codex/skills/${name}"
          mkdir -p "$HOME/.codex/skills/${name}"
          install -m 644 ${lib.escapeShellArg "${standaloneSkillTexts.${name}}"} "$HOME/.codex/skills/${name}/SKILL.md"
        ''
    ) ai.skills
  );
in
{
  config = lib.mkIf cfg.features.enableCodex {
    home.packages = [ pkgs.codex ];

    home.file = {
      ".codex/config.toml".text = codexConfigToml;
      ".codex/AGENTS.md".text = agentsMd;
    };

    home.activation.materializeCodexSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.codex/skills"
      ${materializeSkillsScript}
    '';
  };
}
