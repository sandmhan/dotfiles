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

  # Theme switcher: updates flake.nix activeTheme variable, then runs HM switch
  theme-switch = pkgs.writeShellScriptBin "theme-switch" ''
    set -euo pipefail
    DOTFILES="''${HOME}/dotfiles"
    THEMES_DIR="''${DOTFILES}/themes"

    # Build theme list with polarity labels for Rofi
    THEME=$(ls -1d "''${THEMES_DIR}"/*/  \
      | xargs -I{} basename {} \
      | while read t; do
          pol=$(cat "''${THEMES_DIR}/''${t}/polarity.txt" 2>/dev/null || echo "?")
          echo "''${t} [''${pol}]"
        done \
      | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Theme" -theme-str 'window {width: 40%;}' \
      | ${pkgs.gawk}/bin/awk '{print $1}')

    [[ -z "''${THEME}" ]] && exit 0
    [[ -d "''${THEMES_DIR}/''${THEME}" ]] || { ${pkgs.libnotify}/bin/notify-send "Theme not found" "''${THEME}"; exit 1; }

    # Update activeTheme in flake.nix (pure — no --impure needed)
    ${pkgs.gnused}/bin/sed -i 's|activeTheme = ".*";|activeTheme = "'"''${THEME}"'";|' "''${DOTFILES}/flake.nix"

    # Fast HM rebuild (only theme configs change)
    ${pkgs.libnotify}/bin/notify-send "Switching theme..." "''${THEME}"
    cd "''${DOTFILES}"
    ${pkgs.home-manager}/bin/home-manager switch --flake .#sandmhan 2>&1 | tail -1
    ${pkgs.sway}/bin/swaymsg reload 2>/dev/null || true
    pol=$(cat "''${THEMES_DIR}/''${THEME}/polarity.txt" 2>/dev/null || echo "unknown")
    ${pkgs.libnotify}/bin/notify-send "Theme active" "''${THEME} (''${pol})"
  '';
in
{
  # Stylix theming — sourced from local themes/ directory
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

  # Font configuration
  fonts.fontconfig.enable = lib.mkIf cfg.features.enableFonts true;

  # Theme switcher script (desktop only)
  home.packages = lib.optionals cfg.features.enableWindowManager [
    theme-switch
  ];
}
