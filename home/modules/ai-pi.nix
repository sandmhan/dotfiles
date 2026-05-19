# Pi coding agent integration.
# Exposes shared AI skills through pi's global discovery directory.
{
  lib,
  config,
  ...
}:
let
  cfg = config.myHome;
  ai = cfg.ai;

  piSkillFiles =
    let
      dirSkills = lib.mapAttrs' (
        name: skill:
        lib.nameValuePair ".pi/agent/skills/${name}" {
          source = skill.sourceDir;
          recursive = true;
          force = true;
        }
      ) (lib.filterAttrs (_: s: s.sourceDir != null) ai.skills);

      standaloneSkills = lib.mapAttrs' (
        name: skill:
        lib.nameValuePair ".pi/agent/skills/${name}/SKILL.md" {
          text = skill.content;
          force = true;
        }
      ) (lib.filterAttrs (_: s: s.sourceDir == null) ai.skills);
    in
    dirSkills // standaloneSkills;
in
{
  config = lib.mkIf cfg.features.enablePi {
    home.file = piSkillFiles;
  };
}
