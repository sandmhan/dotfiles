{
  lib,
  pkgs,
  config,
  userSettings,
  ...
}:
let
  cfg = config.myHome;

  activeTheme = userSettings.theme;
  themesDir = ../../themes;

  # Pre-generate base16 shell color scripts for all themes at build time.
  # Each script sets the terminal palette via OSC escape sequences —
  # works in alacritty, kitty, and through tmux. No rebuild needed.
  themeScripts = pkgs.runCommand "base16-theme-scripts" { } ''
        mkdir -p $out

        for dir in ${themesDir}/*/; do
          name=$(basename "$dir")
          yaml="$dir/$name.yaml"
          [ -f "$yaml" ] || continue

          # Parse the simple base16 YAML (key: "value" format)
          extract() { grep "^$1:" "$yaml" | sed 's/.*"\(.*\)".*/\1/' | head -1; }

          base00=$(extract base00)
          base01=$(extract base01)
          base02=$(extract base02)
          base03=$(extract base03)
          base04=$(extract base04)
          base05=$(extract base05)
          base06=$(extract base06)
          base07=$(extract base07)
          base08=$(extract base08)
          base09=$(extract base09)
          base0A=$(extract base0A)
          base0B=$(extract base0B)
          base0C=$(extract base0C)
          base0D=$(extract base0D)
          base0E=$(extract base0E)
          base0F=$(extract base0F)

          polarity="dark"
          [ -f "$dir/polarity.txt" ] && polarity=$(cat "$dir/polarity.txt" | tr -d '\n')

          cat > "$out/$name.sh" << THEME_EOF
    #!/usr/bin/env bash
    # Base16 theme: $name ($polarity)
    # Sets terminal color palette via OSC escape sequences

    set_color() {
      local idx=\$1 hex=\$2
      local r=\''${hex:0:2} g=\''${hex:2:2} b=\''${hex:4:2}
      printf '\033]4;%d;rgb:%s/%s/%s\033\\' "\$idx" "\$r" "\$g" "\$b"
    }

    # ANSI palette (0-15)
    set_color 0  "$base00"   # Black
    set_color 1  "$base08"   # Red
    set_color 2  "$base0B"   # Green
    set_color 3  "$base0A"   # Yellow
    set_color 4  "$base0D"   # Blue
    set_color 5  "$base0E"   # Magenta
    set_color 6  "$base0C"   # Cyan
    set_color 7  "$base05"   # White
    set_color 8  "$base03"   # Bright Black
    set_color 9  "$base09"   # Bright Red (Orange in base16)
    set_color 10 "$base0B"   # Bright Green
    set_color 11 "$base0A"   # Bright Yellow
    set_color 12 "$base0D"   # Bright Blue
    set_color 13 "$base0E"   # Bright Magenta
    set_color 14 "$base0C"   # Bright Cyan
    set_color 15 "$base07"   # Bright White

    # Foreground, background, cursor
    printf '\033]10;rgb:%s/%s/%s\033\\' "${"base05:0:2"}" "${"base05:2:2"}" "${"base05:4:2"}"
    printf '\033]11;rgb:%s/%s/%s\033\\' "${"base00:0:2"}" "${"base00:2:2"}" "${"base00:4:2"}"
    printf '\033]12;rgb:%s/%s/%s\033\\' "${"base05:0:2"}" "${"base05:2:2"}" "${"base05:4:2"}"

    # Export for other tools
    export BASE16_THEME="$name"
    export BASE16_POLARITY="$polarity"
    THEME_EOF

          chmod +x "$out/$name.sh"
        done
  '';

  # Rofi-based theme picker — instant swap, no rebuild
  theme-switch = pkgs.writeShellScriptBin "theme-switch" ''
    set -euo pipefail
    THEMES_DIR="${themeScripts}"
    LOCAL_THEMES="$HOME/dotfiles/themes"

    # Build theme list with polarity labels for Rofi
    THEME=$(ls -1 "$THEMES_DIR"/*.sh \
      | xargs -I{} basename {} .sh \
      | while read t; do
          pol="?"
          [ -f "$LOCAL_THEMES/$t/polarity.txt" ] && pol=$(cat "$LOCAL_THEMES/$t/polarity.txt" | tr -d '\n')
          echo "$t [$pol]"
        done \
      | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Theme" -theme-str 'window {width: 40%;}' \
      | ${pkgs.gawk}/bin/awk '{print $1}')

    [[ -z "$THEME" ]] && exit 0
    [[ -f "$THEMES_DIR/$THEME.sh" ]] || { ${pkgs.libnotify}/bin/notify-send "Theme not found" "$THEME"; exit 1; }

    # Save selection for new shells
    mkdir -p "$HOME/.config"
    echo "$THEME" > "$HOME/.config/active-theme"

    # Apply to current terminal
    source "$THEMES_DIR/$THEME.sh"

    # Apply to all tmux panes (if in tmux)
    if [ -n "''${TMUX:-}" ]; then
      for pane in $(${pkgs.tmux}/bin/tmux list-panes -a -F '#{pane_id}'); do
        ${pkgs.tmux}/bin/tmux send-keys -t "$pane" "source $THEMES_DIR/$THEME.sh" Enter 2>/dev/null || true
      done
    fi

    # Update GTK dark/light preference based on polarity
    pol="?"
    [ -f "$LOCAL_THEMES/$THEME/polarity.txt" ] && pol=$(cat "$LOCAL_THEMES/$THEME/polarity.txt" | tr -d '\n')
    if [ "$pol" = "dark" ]; then
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
    elif [ "$pol" = "light" ]; then
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'" 2>/dev/null || true
    fi

    ${pkgs.libnotify}/bin/notify-send "Theme active" "$THEME ($pol)"
  '';
in
{
  # Stylix theming — manages the default/build-time theme
  stylix = {
    enable = true;
    base16Scheme = "${themesDir}/${activeTheme}/${activeTheme}.yaml";
    polarity = lib.removeSuffix "\n" (builtins.readFile "${themesDir}/${activeTheme}/polarity.txt");
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.blex-mono;
        name = "BlexMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
    # Wallpaper infrastructure — ready to enable when desired:
    # image = pkgs.fetchurl {
    #   url = builtins.readFile "${themesDir}/${activeTheme}/backgroundurl.txt";
    #   sha256 = builtins.readFile "${themesDir}/${activeTheme}/backgroundsha256.txt";
    # };
  };

  # Install pre-generated theme scripts for runtime access
  home.file.".local/share/base16-themes".source = themeScripts;

  # Auto-source active theme on new shell (if one was selected)
  programs.bash.initExtra = ''
    # Load runtime theme override if set by theme-switch
    if [ -f "$HOME/.config/active-theme" ]; then
      _theme=$(cat "$HOME/.config/active-theme" | tr -d '\n')
      _script="$HOME/.local/share/base16-themes/$_theme.sh"
      if [ -f "$_script" ]; then
        source "$_script"
      fi
    fi
  '';

  # Font configuration
  fonts.fontconfig.enable = lib.mkIf cfg.features.enableFonts true;

  # Theme switcher script (desktop only)
  home.packages = lib.optionals cfg.features.enableWindowManager [
    theme-switch
  ];
}
