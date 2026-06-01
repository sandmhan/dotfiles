# Claude Code provider module.
# Bootstraps shared AI skills/rules into writable Claude Code files.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.myHome;
  ai = cfg.ai;
  jsonFormat = pkgs.formats.json { };

  settingsJson = jsonFormat.generate "claude-code-settings.json" (
    ai.claude.settings
    // {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    }
  );

  templateName = prefix: name: "${prefix}-${builtins.hashString "sha256" name}.md";

  ruleTexts = lib.mapAttrs (
    name: content: pkgs.writeText (templateName "claude-rule" name) content
  ) ai.rules;

  standaloneSkillTexts = lib.mapAttrs (
    name: skill: pkgs.writeText (templateName "claude-skill" name) skill.content
  ) (lib.filterAttrs (_: s: s.sourceDir == null) ai.skills);

  materializeRulesScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: source: ''
      bootstrap_file ${lib.escapeShellArg "${source}"} "$HOME"/${lib.escapeShellArg ".claude/rules/${name}.md"}
    '') ruleTexts
  );

  materializeSkillsScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: skill:
      if skill.sourceDir != null then
        ''
          bootstrap_dir ${lib.escapeShellArg "${skill.sourceDir}"} "$HOME"/${lib.escapeShellArg ".claude/skills/${name}"}
        ''
      else
        ''
          bootstrap_file ${lib.escapeShellArg "${standaloneSkillTexts.${name}}"} "$HOME"/${lib.escapeShellArg ".claude/skills/${name}/SKILL.md"}
        ''
    ) ai.skills
  );
in
{
  options.myHome.ai.claude.settings = lib.mkOption {
    inherit (jsonFormat) type;
    default = {
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
    description = ''
      Default Claude Code settings bootstrapped to ~/.claude/settings.json.
      Activation replaces old Home Manager symlinks with regular files, but
      preserves existing regular user files for runtime edits.
    '';
  };

  config = lib.mkIf cfg.features.enableClaudeCode {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
    };

    home.activation.materializeClaudeCodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ -v DRY_RUN ]]; then
        echo "Skipping Claude Code config materialization during dry-run"
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

      ensure_writable_dir "$HOME/.claude"
      ensure_writable_dir "$HOME/.claude/rules"
      ensure_writable_dir "$HOME/.claude/skills"

      bootstrap_file ${lib.escapeShellArg "${settingsJson}"} "$HOME"/${lib.escapeShellArg ".claude/settings.json"}
        ${materializeRulesScript}
        ${materializeSkillsScript}
      fi
    '';
  };
}
