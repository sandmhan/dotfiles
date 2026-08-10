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
  # Each theme gets six files:
  #   <name>.sh            — terminal OSC escape sequences
  #   <name>-sway.conf     — sway client.* color declarations
  #   <name>-colors.css    — GTK @define-color declarations for waybar
  #   <name>-swaync.css    — SwayNotificationCenter CSS variables
  #   <name>-tmux.conf     — tmux color declarations
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

          # ── 4. SwayNotificationCenter color variables ─────────────────────
          # The upstream stylesheet consumes RGB triplets for notification
          # opacity, so preserve those alongside the Base16 named colors.
          hex_rgb() {
            hex="$1"
            printf '%d, %d, %d' \
              "$((16#''${hex:0:2}))" \
              "$((16#''${hex:2:2}))" \
              "$((16#''${hex:4:2}))"
          }

          rgb00=$(hex_rgb "$base00")
          rgb01=$(hex_rgb "$base01")
          rgb0D=$(hex_rgb "$base0D")

          cat > "$out/$name-swaync.css" << SWAYNC_EOF
    @define-color base00 #$base00;
    @define-color base01 #$base01;
    @define-color base02 #$base02;
    @define-color base03 #$base03;
    @define-color base05 #$base05;
    @define-color base08 #$base08;
    @define-color base0A #$base0A;
    @define-color base0B #$base0B;
    @define-color base0D #$base0D;

    :root {
      --cc-bg: rgba($rgb00, 0.96);
      --noti-border-color: #$base02;
      --noti-bg: $rgb01;
      --noti-bg-alpha: 0.96;
      --noti-bg-darker: #$base00;
      --noti-bg-hover: #$base02;
      --noti-bg-focus: rgba($rgb0D, 0.24);
      --noti-close-bg: #$base02;
      --noti-close-bg-hover: #$base03;
      --text-color: #$base05;
      --text-color-disabled: #$base03;
      --bg-selected: #$base0D;
      --border-radius: 8px;
      --font-size-body: 13px;
      --font-size-summary: 14px;
    }
    SWAYNC_EOF

          # ── 5. Tmux colour config (mirrors Stylix/tinted-theming template) ──
          cat > "$out/$name-tmux.conf" << TMUX_EOF
    # Base16 theme: $name — runtime override (sourced by active-tmux.conf)
    set-option -g  status-style                  "fg=#$base05,bg=#$base01"
    set-window-option -g window-status-style     "fg=#$base05,bg=#$base01"
    set-window-option -g window-status-current-style "fg=#$base0A,bg=#$base01"
    set-option -g  pane-border-style             "fg=#$base01"
    set-option -g  pane-active-border-style      "fg=#$base04"
    set-option -g  message-style                 "fg=#$base05,bg=#$base02"
    set-option -g  message-command-style         "fg=#$base05,bg=#$base02"
    set-option -g  display-panes-active-colour   "#$base04"
    set-option -g  display-panes-colour          "#$base01"
    set-window-option -g clock-mode-colour       "#$base0D"
    set-window-option -g mode-style              "fg=#$base04,bg=#$base02"
    set-window-option -g window-status-bell-style "fg=#$base01,bg=#$base08"
    set-window-option -g window-status-activity-style "fg=#$base05,bg=#$base01"
    TMUX_EOF

      # ── 6. Rofi complete minimal theme ─────────────────────────────────
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

    #pulseaudio,
    #network,
    #mpd,
    #temperature,
    #memory,
    #cpu,
    #battery,
    #custom-kdeconnect,
    #custom-tailscale {
      padding: 0 8px;
    }

    #custom-notification {
      padding: 0 8px;
      color: @base05;
    }

    #battery {
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
      color: @base0D;
    }

    #memory {
      color: @base0E;
    }

    #temperature {
      color: @base0C;
    }

    #temperature.critical {
      background-color: @base08;
      color: @base00;
    }

    #network {
      color: @base05;
    }

    #network.disconnected {
      color: @base08;
    }

    #pulseaudio {
      color: @base05;
    }

    #pulseaudio.muted {
      color: @base03;
    }

    #mpd {
      color: @base0D;
    }

    #mpd.disconnected,
    #mpd.stopped {
      color: @base03;
    }

    #tray {
      padding: 0 8px;
    }

    #custom-kdeconnect.connected,
    #custom-tailscale.connected {
      color: @base0B;
    }

    #custom-kdeconnect.disconnected,
    #custom-tailscale.disconnected {
      color: @base03;
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
      ${pkgs.findutils}/bin/find "$THEMES_DIR" -maxdepth 1 -type f -name '*.sh' -printf '%f\n' \
        | ${pkgs.gnused}/bin/sed 's/\.sh$//' \
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
      ${pkgs.libnotify}/bin/notify-send --app-name="Gaia Theme" \
        "Theme not found" "$THEME"
      exit 1
    }

    mkdir -p "$HOME/.config" "$HOME/.config/waybar" "$HOME/.config/rofi" \
      "$HOME/.config/swaync" "$HOME/.local/share"
    echo "$THEME" > "$HOME/.config/active-theme"

    pol="?"
    [ -f "$LOCAL_THEMES/$THEME/polarity.txt" ] && pol=$(tr -d '\n' < "$LOCAL_THEMES/$THEME/polarity.txt")

    # ── Phase 1: write all config files (fast disk writes, no signals yet) ──
    cat "$THEMES_DIR/$THEME-sway.conf"  > "$HOME/.local/share/active-sway.conf"
    cat "$THEMES_DIR/$THEME-colors.css" > "$HOME/.config/waybar/colors.css"
    cat "$THEMES_DIR/$THEME-swaync.css" > "$HOME/.config/swaync/colors.css"
    cat "$THEMES_DIR/$THEME-rofi.rasi"  > "$HOME/.config/rofi/active-theme.rasi"
    cat "$THEMES_DIR/$THEME-tmux.conf"  > "$HOME/.local/share/active-tmux.conf"

    # ── Phase 2: terminal ANSI colours — write to all open pty slaves ───────
    # Standalone terminals: alacritty reads from its pty master → OSC applied.
    # Tmux client tty: raw mode, sequences pass through to outer terminal.
    # Tmux inner panes: tmux intercepts OSC 4 silently — harmless.
    for pts in /dev/pts/[0-9]*; do
      [ -w "$pts" ] && [ -c "$pts" ] || continue
      bash "$THEMES_DIR/$THEME.sh" > "$pts" 2>/dev/null || true
    done

    # ── Phase 3: all GUI reloads fired concurrently ──────────────────────────
    # Waybar: SIGUSR2 reloads CSS. Note: waybar recreates its window on reload,
    #   causing a brief flicker — this is a waybar limitation.
    # Sway window colours: send client.* IPC commands directly — no swaymsg
    #   reload needed. The include file ensures colours survive a sway restart.
    # Tmux: source the new conf via each server's socket.
    pkill -SIGUSR2 waybar 2>/dev/null &
    ${pkgs.swaynotificationcenter}/bin/swaync-client -rs 2>/dev/null &
    grep '^client\.' "$THEMES_DIR/$THEME-sway.conf" \
      | while IFS= read -r line; do
          ${pkgs.sway}/bin/swaymsg "$line" 2>/dev/null || true
        done &
    for sock in /tmp/tmux-"$(id -u)"/*; do
      [ -S "$sock" ] && ${pkgs.tmux}/bin/tmux -S "$sock" \
        source-file "$HOME/.local/share/active-tmux.conf" 2>/dev/null &
    done

    # ── Phase 4: background ancillary updates ───────────────────────────────
    if [ "$pol" = "dark" ]; then
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null &
    elif [ "$pol" = "light" ]; then
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'" 2>/dev/null &
    fi

    wait
    ${pkgs.libnotify}/bin/notify-send --app-name="Gaia Theme" \
      --urgency=low "Theme active" "$THEME ($pol)"
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
    targets.swaync.enable = false;
    targets.tmux.enable = false;
    # Wallpaper infrastructure — ready to enable when desired:
    # image = pkgs.fetchurl {
    #   url = builtins.readFile "${themesDir}/${activeTheme}/backgroundurl.txt";
    #   sha256 = builtins.readFile "${themesDir}/${activeTheme}/backgroundsha256.txt";
    # };
  };

  # Waybar CSS: structural styles using @define-color names; colors.css is
  # writable at runtime and updated by theme-switch without restarting waybar.
  programs.waybar.style = waybarCSS;

  services.swaync.style = lib.mkIf cfg.features.enableWindowManager ''
    @import url("file://${pkgs.swaynotificationcenter}/etc/xdg/swaync/style.css");
    @import url("file://${homeDir}/.config/swaync/colors.css");

    * {
      font-family: "BlexMono Nerd Font", monospace;
    }

    .notification-row .notification-background {
      padding: 4px 8px;
    }

    .notification-row .notification-background .notification.critical {
      border-color: @base08;
    }

    .control-center {
      border: 1px solid @base02;
      border-radius: 8px;
    }
  '';

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

    mkdir -p "$HOME/.config/waybar" "$HOME/.config/rofi" \
      "$HOME/.config/swaync" "$HOME/.local/share"

    install -m 644 "${themeScripts}/$ACTIVE-colors.css"   "$HOME/.config/waybar/colors.css"
    install -m 644 "${themeScripts}/$ACTIVE-swaync.css"   "$HOME/.config/swaync/colors.css"
    install -m 644 "${themeScripts}/$ACTIVE-sway.conf"    "$HOME/.local/share/active-sway.conf"
    install -m 644 "${themeScripts}/$ACTIVE-rofi.rasi"    "$HOME/.config/rofi/active-theme.rasi"
    install -m 644 "${themeScripts}/$ACTIVE-tmux.conf"    "$HOME/.local/share/active-tmux.conf"
  '';

  # Tmux: source runtime theme on every new server start (overrides Stylix defaults).
  # Uses if-shell so headless configs don't break if the file doesn't exist yet.
  programs.tmux.extraConfig = lib.mkAfter ''
    if-shell 'test -f ${homeDir}/.local/share/active-tmux.conf' 'source-file ${homeDir}/.local/share/active-tmux.conf'
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
