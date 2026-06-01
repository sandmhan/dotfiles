# Codex provider module.
# Bootstraps shared AI skills/rules into Codex's writable file-based config.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.myHome;
  ai = cfg.ai;

  configTomlTemplate = pkgs.writeText "codex-config.toml" ai.codex.configToml;

  # Build AGENTS.md by concatenating all rules
  agentsMd = lib.concatStringsSep "\n\n" (lib.attrValues ai.rules);
  agentsMdTemplate = pkgs.writeText "codex-AGENTS.md" agentsMd;

  templateName = prefix: name: "${prefix}-${builtins.hashString "sha256" name}.md";

  standaloneSkillTexts = lib.mapAttrs (
    name: skill: pkgs.writeText (templateName "codex-skill" name) skill.content
  ) (lib.filterAttrs (_: s: s.sourceDir == null) ai.skills);

  materializeSkillsScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: skill:
      if skill.sourceDir != null then
        ''
          bootstrap_dir ${lib.escapeShellArg "${skill.sourceDir}"} "$HOME"/${lib.escapeShellArg ".codex/skills/${name}"}
        ''
      else
        ''
          bootstrap_file ${lib.escapeShellArg "${standaloneSkillTexts.${name}}"} "$HOME"/${lib.escapeShellArg ".codex/skills/${name}/SKILL.md"}
        ''
    ) ai.skills
  );
in
{
  options.myHome.ai.codex.configToml = lib.mkOption {
    type = lib.types.lines;
    default = ''
      model = "gpt-5-codex"
      model_reasoning_effort = "medium"
      approval_policy = "on-request"
      sandbox_mode = "workspace-write"

      [features]
      web_search = true
      memories = true
    '';
    description = ''
      Default Codex CLI config bootstrapped to ~/.codex/config.toml.
      Activation replaces old Home Manager symlinks with regular files, but
      preserves existing regular user files for runtime edits.
    '';
  };

  config = lib.mkIf cfg.features.enableCodex {
    home.packages = [ pkgs.codex ];

    home.activation.materializeCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ -v DRY_RUN ]]; then
        echo "Skipping Codex config materialization during dry-run"
      else
        bootstrap_file() {
        local source="$1"
        local target="$2"

        mkdir -p "$(dirname "$target")"

        if [ -L "$target" ]; then
          rm "$target"
        elif [ -e "$target" ]; then
          if [ -f "$target" ]; then
            chmod u+rw "$target"
          else
            echo "Skipping $target: exists and is not a regular file" >&2
          fi
          return 0
        fi

        install -m 644 "$source" "$target"
      }

      ensure_writable_dir() {
        local target="$1"
        local tmp=""

        if [ -L "$target" ]; then
          if [ -d "$target" ]; then
            tmp="$(mktemp -d)"
            ${pkgs.coreutils}/bin/cp -R --no-preserve=mode,ownership "$target/." "$tmp/" 2>/dev/null || true
          fi
          rm "$target"
        fi

        mkdir -p "$target"
        if [ -n "$tmp" ]; then
          ${pkgs.coreutils}/bin/cp -R --no-preserve=mode,ownership "$tmp/." "$target/"
          rm -rf "$tmp"
        fi
        chmod u+rwx "$target"
      }

      copy_missing_dir_entries() {
        local source="$1"
        local target="$2"
        local source_entry=""
        local relative_entry=""
        local target_entry=""

        while IFS= read -r -d "" source_entry; do
          relative_entry="''${source_entry#"$source"/}"
          target_entry="$target/$relative_entry"

          if [ -d "$source_entry" ]; then
            mkdir -p "$target_entry"
          elif [ -f "$source_entry" ]; then
            mkdir -p "$(dirname "$target_entry")"
            if [ -L "$target_entry" ]; then
              rm "$target_entry"
            fi
            if [ ! -e "$target_entry" ]; then
              install -m 644 "$source_entry" "$target_entry"
            elif [ -f "$target_entry" ]; then
              chmod u+rw "$target_entry"
            else
              echo "Skipping $target_entry: exists and is not a regular file" >&2
            fi
          fi
        done < <(${pkgs.findutils}/bin/find "$source" -mindepth 1 -print0)
      }

      bootstrap_dir() {
        local source="$1"
        local target="$2"

        ensure_writable_dir "$(dirname "$target")"

        if [ -L "$target" ]; then
          rm "$target"
        elif [ -e "$target" ] && [ ! -d "$target" ]; then
          echo "Skipping $target: exists and is not a directory" >&2
          return 0
        fi

        mkdir -p "$target"
        copy_missing_dir_entries "$source" "$target"
        chmod -R u+rwX,go-w "$target"
      }

      ensure_writable_dir "$HOME/.codex"
      ensure_writable_dir "$HOME/.codex/skills"

      bootstrap_file ${lib.escapeShellArg "${configTomlTemplate}"} "$HOME"/${lib.escapeShellArg ".codex/config.toml"}
        bootstrap_file ${lib.escapeShellArg "${agentsMdTemplate}"} "$HOME"/${lib.escapeShellArg ".codex/AGENTS.md"}
        ${materializeSkillsScript}
      fi
    '';
  };
}
