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
  homeDir = config.home.homeDirectory;

  # Build-time: generate all per-theme files for runtime switching.
  # Each theme gets four files:
  #   <name>.sh            — terminal OSC escape sequences
  #   <name>-sway.conf     — sway client.* color declarations
  #   <name>-colors.css    — GTK @define-color declarations for waybar
  #   <name>-rofi.rasi     — complete minimal rofi theme
  themeScripts = pkgs.runCommand "base16-theme-scripts" { } ''
        mkdir -p $out

        for dir in ${themesDir}/*/; do
          name=$(basename "$dir")
          yaml="$dir/$name.yaml"
          [ -f "$yaml" ] || continue

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

          # ── 1. Terminal OSC escape script ──────────────────────────────────
          cat > "$out/$name.sh" << THEME_EOF
    #!/usr/bin/env bash
    # Base16 theme: $name ($polarity)
    # Sets terminal color palette via OSC escape sequences

    set_color() {
      local idx=\$1 hex=\$2
      local r=\''${hex:0:2} g=\''${hex:2:2} b=\''${hex:4:2}
      printf '\033]4;%d;rgb:%s/%s/%s\033\\' "\$idx" "\$r" "\$g" "\$b"
    }

    set_color 0  "$base00"
    set_color 1  "$base08"
    set_color 2  "$base0B"
    set_color 3  "$base0A"
    set_color 4  "$base0D"
    set_color 5  "$base0E"
    set_color 6  "$base0C"
    set_color 7  "$base05"
    set_color 8  "$base03"
    set_color 9  "$base09"
    set_color 10 "$base0B"
    set_color 11 "$base0A"
    set_color 12 "$base0D"
    set_color 13 "$base0E"
    set_color 14 "$base0C"
    set_color 15 "$base07"

    export BASE16_THEME="$name"
    export BASE16_POLARITY="$polarity"
    THEME_EOF
          chmod +x "$out/$name.sh"

          # ── 2. Sway window color declarations ──────────────────────────────
          # Placed at end of sway config via include — last declaration wins.
          cat > "$out/$name-sway.conf" << SWAY_EOF
    # Base16 theme: $name
    # client.focused    <border>   <bg>       <text>     <indicator> <child>
    client.focused          #$base0D #$base0D #$base00 #$base0C  #$base0D
    client.focused_inactive #$base02 #$base01 #$base05 #$base03  #$base01
    client.unfocused        #$base01 #$base00 #$base03 #$base01  #$base00
    client.urgent           #$base08 #$base08 #$base00 #$base08  #$base08
    client.placeholder      #$base00 #$base00 #$base05 #$base00  #$base00
    client.background       #$base00
    SWAY_EOF

          # ── 3. Waybar GTK color variable declarations ───────────────────────
          # Imported by style.css at waybar startup and on SIGUSR2 reload.
          cat > "$out/$name-colors.css" << COLORS_EOF
    @define-color base00 #$base00;
    @define-color base01 #$base01;
    @define-color base02 #$base02;
    @define-color base03 #$base03;
    @define-color base04 #$base04;
    @define-color base05 #$base05;
    @define-color base06 #$base06;
    @define-color base07 #$base07;
    @define-color base08 #$base08;
    @define-color base09 #$base09;
    @define-color base0A #$base0A;
    @define-color base0B #$base0B;
    @define-color base0C #$base0C;
    @define-color base0D #$base0D;
    @define-color base0E #$base0E;
    @define-color base0F #$base0F;
    COLORS_EOF

          # ── 4. Rofi complete minimal theme ─────────────────────────────────
          cat > "$out/$name-rofi.rasi" << RASI_EOF
    * {
      background-color: #$base00;
      text-color:       #$base05;
      border-color:     #$base0D;
    }

    window {
      background-color: @background-color;
      border: 2px;
      padding: 5px;
    }

    mainbox {
      border: 0;
      padding: 0;
    }

    inputbar {
      children: [prompt, textbox-prompt-colon, entry];
      background-color: #$base01;
      padding: 6px;
    }

    prompt {
      spacing: 0;
      text-color: #$base0D;
    }

    textbox-prompt-colon {
      expand: false;
      str: ":";
      margin: 0 0.3em 0 0;
      text-color: @text-color;
    }

    entry {
      spacing: 0;
      text-color: @text-color;
    }

    listview {
      fixed-height: 0;
      border: 2px 0 0;
      border-color: #$base01;
      padding: 2px 0 0;
      spacing: 2px;
      scrollbar: false;
    }

    element {
      border: 0;
      padding: 5px;
    }

    element.normal.normal {
      background-color: @background-color;
      text-color: @text-color;
    }

    element.normal.active {
      background-color: @background-color;
      text-color: #$base0B;
    }

    element.normal.urgent {
      background-color: @background-color;
      text-color: #$base08;
    }

    element.selected.normal {
      background-color: #$base0D;
      text-color: #$base00;
    }

    element.selected.active {
      background-color: #$base0B;
      text-color: #$base00;
    }

    element.selected.urgent {
      background-color: #$base08;
      text-color: #$base00;
    }

    element.alternate.normal {
      background-color: #$base01;
      text-color: @text-color;
    }

    element.alternate.active {
      background-color: #$base01;
      text-color: #$base0B;
    }

    element.alternate.urgent {
      background-color: #$base01;
      text-color: #$base08;
    }
    RASI_EOF

        done
  '';

  # Waybar structural CSS. Colors come from the imported colors.css which
  # theme-switch overwrites at runtime. SIGUSR2 re-reads the whole stylesheet.
  # @import MUST be the first rule in GTK CSS.
  waybarCSS = ''
    @import url("file://${homeDir}/.config/waybar/colors.css");

    * {
      font-family: "BlexMono Nerd Font", monospace;
      font-size: 13px;
      min-height: 0;
      border: none;
      border-radius: 0;
    }

    #waybar {
      background-color: @base00;
      color: @base05;
      border-bottom: 2px solid @base01;
    }

    #workspaces {
      margin: 0 5px;
    }

    #workspaces button {
      padding: 0 8px;
      background-color: @base00;
      color: @base03;
    }

    #workspaces button:hover {
      background-color: @base01;
      color: @base05;
    }

    #workspaces button.focused {
      background-color: @base02;
      color: @base0D;
      border-bottom: 2px solid @base0D;
    }

    #workspaces button.urgent {
      background-color: @base08;
      color: @base00;
    }

    #mode {
      background-color: @base0A;
      color: @base00;
      padding: 0 8px;
      font-weight: bold;
    }

    #window {
      color: @base05;
      padding: 0 10px;
    }

    #clock {
      padding: 0 12px;
      color: @base05;
      font-weight: bold;
    }

    #battery {
      padding: 0 10px;
      color: @base0B;
    }

    #battery.warning {
      color: @base0A;
    }

    #battery.critical {
      color: @base08;
      font-weight: bold;
    }

    #battery.charging {
      color: @base0B;
    }

    #cpu {
      padding: 0 10px;
      color: @base0D;
    }

    #memory {
      padding: 0 10px;
      color: @base0E;
    }

    #temperature {
      padding: 0 10px;
      color: @base0C;
    }

    #temperature.critical {
      background-color: @base08;
      color: @base00;
    }

    #network {
      padding: 0 10px;
      color: @base05;
    }

    #network.disconnected {
      color: @base08;
    }

    #pulseaudio {
      padding: 0 10px;
      color: @base05;
    }

    #pulseaudio.muted {
      color: @base03;
    }

    #mpd {
      padding: 0 10px;
      color: @base0D;
    }

    #mpd.disconnected,
    #mpd.stopped {
      color: @base03;
    }

    #tray {
      padding: 0 8px;
    }

    tooltip {
      background-color: @base01;
      color: @base05;
      border: 1px solid @base0D;
    }
  '';

  # Rofi-based theme picker with inline color swatch preview
  theme-switch = pkgs.writeShellScriptBin "theme-switch" ''
    set -euo pipefail
    THEMES_DIR="${themeScripts}"
    LOCAL_THEMES="$HOME/dotfiles/themes"

    # Build entry list with Pango color swatches for visual preview.
    # Format: <span>colored blocks</span>  theme-name [polarity]
    THEME=$(
      ls -1 "$THEMES_DIR"/*.sh \
        | xargs -I{} basename {} .sh \
        | while read -r t; do
            pol="?"
            [ -f "$LOCAL_THEMES/$t/polarity.txt" ] && pol=$(tr -d '\n' < "$LOCAL_THEMES/$t/polarity.txt")

            css="$THEMES_DIR/$t-colors.css"
            if [ -f "$css" ]; then
              c08=$(grep 'base08' "$css" | sed 's/.*#\([0-9a-fA-F]*\);.*/\1/')
              c0B=$(grep 'base0B' "$css" | sed 's/.*#\([0-9a-fA-F]*\);.*/\1/')
              c0D=$(grep 'base0D' "$css" | sed 's/.*#\([0-9a-fA-F]*\);.*/\1/')
              c0E=$(grep 'base0E' "$css" | sed 's/.*#\([0-9a-fA-F]*\);.*/\1/')
              printf '<span bgcolor="#%s" fgcolor="#%s">  </span><span bgcolor="#%s" fgcolor="#%s">  </span><span bgcolor="#%s" fgcolor="#%s">  </span><span bgcolor="#%s" fgcolor="#%s">  </span>  %s [%s]\n' \
                "$c08" "$c08" "$c0B" "$c0B" "$c0D" "$c0D" "$c0E" "$c0E" "$t" "$pol"
            else
              echo "  $t [$pol]"
            fi
          done \
        | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Theme" -markup-rows \
            -theme-str 'window {width: 45%;} listview {lines: 12;}' \
        | ${pkgs.gawk}/bin/awk '{ gsub(/<[^>]*>/, ""); n=split($0,a," "); for(i=n;i>=1;i--) { if(a[i]!~/^\[/ && a[i]!="") { print a[i]; exit } } }'
    )

    [[ -z "$THEME" ]] && exit 0
    [[ -f "$THEMES_DIR/$THEME.sh" ]] || {
      ${pkgs.libnotify}/bin/notify-send "Theme not found" "$THEME"
      exit 1
    }

    # Persist selection for new shells
    mkdir -p "$HOME/.config"
    echo "$THEME" > "$HOME/.config/active-theme"

    # ── 1. Terminal: write OSC sequences directly to all open pty slaves ──
    # theme-switch runs without a controlling terminal (launched by sway),
    # so sourcing the script in-process does nothing. Instead we write
    # directly to each /dev/pts slave the user owns:
    #   - standalone alacritty/kitty: the terminal emulator reads from its
    #     pty master and processes the OSC colour sequences immediately
    #   - tmux client tty: tmux is in raw mode, sequences pass straight
    #     through to the outer terminal (alacritty)
    #   - tmux inner pane ptys: tmux intercepts OSC 4 silently — harmless
    for pts in /dev/pts/[0-9]*; do
      [ -w "$pts" ] && [ -c "$pts" ] || continue
      bash "$THEMES_DIR/$THEME.sh" > "$pts" 2>/dev/null || true
    done

    # ── 3. Sway: override window border colors and reload ──────────────────
    cat "$THEMES_DIR/$THEME-sway.conf" > "$HOME/.local/share/active-sway.conf"
    ${pkgs.sway}/bin/swaymsg reload 2>/dev/null || true

    # ── 4. Waybar: write new color vars and reload CSS ─────────────────────
    mkdir -p "$HOME/.config/waybar"
    cat "$THEMES_DIR/$THEME-colors.css" > "$HOME/.config/waybar/colors.css"
    pkill -SIGUSR2 waybar 2>/dev/null || true

    # ── 5. Rofi: write new theme (each invocation is fresh) ────────────────
    cat "$THEMES_DIR/$THEME-rofi.rasi" > "$HOME/.config/rofi/active-theme.rasi"

    # ── 6. GTK dark/light preference ──────────────────────────────────────
    pol="?"
    [ -f "$LOCAL_THEMES/$THEME/polarity.txt" ] && pol=$(tr -d '\n' < "$LOCAL_THEMES/$THEME/polarity.txt")
    if [ "$pol" = "dark" ]; then
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
    elif [ "$pol" = "light" ]; then
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'" 2>/dev/null || true
    fi

    ${pkgs.libnotify}/bin/notify-send "Theme active" "$THEME ($pol)"
  '';
in
{
  # Stylix: manages fonts and most apps.
  # Waybar and rofi are opted out so we can manage their colors at runtime.
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
    targets.waybar.enable = false;
    targets.rofi.enable = false;
    # Wallpaper infrastructure — ready to enable when desired:
    # image = pkgs.fetchurl {
    #   url = builtins.readFile "${themesDir}/${activeTheme}/backgroundurl.txt";
    #   sha256 = builtins.readFile "${themesDir}/${activeTheme}/backgroundsha256.txt";
    # };
  };

  # Waybar CSS: structural styles using @define-color names; colors.css is
  # writable at runtime and updated by theme-switch without restarting waybar.
  programs.waybar.style = waybarCSS;

  # Rofi: point to writable theme file — each invocation reads it fresh.
  programs.rofi.theme = "${homeDir}/.config/rofi/active-theme.rasi";

  # Install all pre-generated theme files (read-only Nix store reference).
  home.file.".local/share/base16-themes".source = themeScripts;

  # Initialize writable theme files at activation time.
  # Syncs to active-theme if one is already selected; falls back to the
  # build-time default. Runs after home.file entries are written.
  home.activation.initThemeFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ACTIVE="${activeTheme}"
    if [ -f "$HOME/.config/active-theme" ]; then
      CANDIDATE=$(tr -d '\n' < "$HOME/.config/active-theme")
      [ -f "${themeScripts}/$CANDIDATE-colors.css" ] && ACTIVE="$CANDIDATE"
    fi

    mkdir -p "$HOME/.config/waybar" "$HOME/.config/rofi" "$HOME/.local/share"

    install -m 644 "${themeScripts}/$ACTIVE-colors.css"   "$HOME/.config/waybar/colors.css"
    install -m 644 "${themeScripts}/$ACTIVE-sway.conf"    "$HOME/.local/share/active-sway.conf"
    install -m 644 "${themeScripts}/$ACTIVE-rofi.rasi"    "$HOME/.config/rofi/active-theme.rasi"
  '';

  # Auto-source active terminal theme on new shell
  programs.bash.initExtra = ''
    if [ -f "$HOME/.config/active-theme" ]; then
      _theme=$(tr -d '\n' < "$HOME/.config/active-theme")
      _script="$HOME/.local/share/base16-themes/$_theme.sh"
      [ -f "$_script" ] && source "$_script"
    fi
  '';

  # Font configuration
  fonts.fontconfig.enable = lib.mkIf cfg.features.enableFonts true;

  # Theme switcher script (desktop only)
  home.packages = lib.optionals cfg.features.enableWindowManager [ theme-switch ];
}
