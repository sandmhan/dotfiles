{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.myHome;

  screenshotDir = "$HOME/Pictures/Screenshots";
  recordingDir = "$HOME/Videos/Recordings";

  screenshot-rofi = pkgs.writeShellScriptBin "screenshot-rofi" ''
    set -uo pipefail

    mkdir -p "${screenshotDir}" "${recordingDir}"

    copy_screenshot() {
      screenshot_path="$1"

      if [ ! -s "$screenshot_path" ]; then
        ${pkgs.libnotify}/bin/notify-send "Screenshot failed" \
          "No image was captured" -t 3000
        return 1
      fi

      if ${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$screenshot_path"; then
        ${pkgs.libnotify}/bin/notify-send "Screenshot" \
          "Saved to Screenshots/ and copied to clipboard" -t 3000
      else
        ${pkgs.libnotify}/bin/notify-send "Screenshot" \
          "Saved to Screenshots/, but clipboard copy failed" -t 4000
        return 1
      fi
    }

    RECORDING_PID=$(${pkgs.procps}/bin/pgrep -x wf-recorder || true)

    if [ -n "$RECORDING_PID" ]; then
      OPTIONS="Stop recording"
    else
      OPTIONS="Fullscreen
    Region
    Window
    Fullscreen (edit)
    Region (edit)
    Record fullscreen
    Record region"
    fi

    CHOICE=$(echo "$OPTIONS" | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Screenshot" -theme-str 'listview { lines: 7; }') || exit 0

    TIMESTAMP=$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S)
    SCREENSHOT_PATH="${screenshotDir}/screenshot_$TIMESTAMP.png"

    case "$CHOICE" in
      "Fullscreen")
        if ${pkgs.grim}/bin/grim "$SCREENSHOT_PATH"; then
          copy_screenshot "$SCREENSHOT_PATH"
        fi
        ;;
      "Region")
        GEOMETRY=$(${pkgs.slurp}/bin/slurp) || exit 0
        if ${pkgs.grim}/bin/grim -g "$GEOMETRY" "$SCREENSHOT_PATH"; then
          copy_screenshot "$SCREENSHOT_PATH"
        fi
        ;;
      "Window")
        GEOMETRY=$(
          ${pkgs.sway}/bin/swaymsg -t get_tree \
            | ${pkgs.jq}/bin/jq -er \
              '.. | objects | select(.focused == true).rect | "\(.x),\(.y) \(.width)x\(.height)"'
        ) || exit 0
        if ${pkgs.grim}/bin/grim -g "$GEOMETRY" "$SCREENSHOT_PATH"; then
          copy_screenshot "$SCREENSHOT_PATH"
        fi
        ;;
      "Fullscreen (edit)")
        if ${pkgs.grim}/bin/grim - \
          | ${pkgs.swappy}/bin/swappy -f - -o "$SCREENSHOT_PATH"; then
          copy_screenshot "$SCREENSHOT_PATH"
        fi
        ;;
      "Region (edit)")
        GEOMETRY=$(${pkgs.slurp}/bin/slurp) || exit 0
        if ${pkgs.grim}/bin/grim -g "$GEOMETRY" - \
          | ${pkgs.swappy}/bin/swappy -f - -o "$SCREENSHOT_PATH"; then
          copy_screenshot "$SCREENSHOT_PATH"
        fi
        ;;
      "Record fullscreen")
        ${pkgs.wf-recorder}/bin/wf-recorder -f "${recordingDir}/recording_$TIMESTAMP.mp4" &
        ${pkgs.libnotify}/bin/notify-send "Recording" \
          "Screen recording started" -t 3000
        ;;
      "Record region")
        GEOMETRY=$(${pkgs.slurp}/bin/slurp) || exit 0
        ${pkgs.wf-recorder}/bin/wf-recorder -g "$GEOMETRY" \
          -f "${recordingDir}/recording_$TIMESTAMP.mp4" &
        ${pkgs.libnotify}/bin/notify-send "Recording" \
          "Region recording started" -t 3000
        ;;
      "Stop recording")
        kill "$RECORDING_PID"
        ${pkgs.libnotify}/bin/notify-send "Recording" \
          "Screen recording saved to Recordings/" -t 3000
        ;;
    esac
  '';
in
{
  config = lib.mkIf cfg.features.enableScreenshotTools {
    home.packages = [
      pkgs.grim
      pkgs.slurp
      pkgs.swappy
      pkgs.wf-recorder
      pkgs.wl-clipboard
      pkgs.libnotify
      screenshot-rofi
    ];

    # Swappy config — save to screenshots dir, use pen as default tool
    xdg.configFile."swappy/config".text = ''
      [Default]
      save_dir=${screenshotDir}
      save_filename_format=screenshot_%Y-%m-%d_%H-%M-%S.png
      show_panel=true
      line_size=5
      text_size=20
      paint_mode=brush
    '';

    # Sway keybindings for screenshot tools
    wayland.windowManager.sway.config.keybindings = {
      "Mod1+S" = "exec screenshot-rofi";
      "Print" =
        "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.swappy}/bin/swappy -f -";
    };
  };
}
