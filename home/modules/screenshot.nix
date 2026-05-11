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
        mkdir -p "${screenshotDir}" "${recordingDir}"

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

        CHOICE=$(echo "$OPTIONS" | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Screenshot" -theme-str 'listview { lines: 7; }')

        TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

        case "$CHOICE" in
          "Fullscreen")
            ${pkgs.grim}/bin/grim "${screenshotDir}/screenshot_$TIMESTAMP.png"
            notify-send "Screenshot" "Saved to Screenshots/" -t 3000
            ;;
          "Region")
            ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" "${screenshotDir}/screenshot_$TIMESTAMP.png"
            notify-send "Screenshot" "Saved to Screenshots/" -t 3000
            ;;
          "Window")
            ${pkgs.grim}/bin/grim -g "$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" "${screenshotDir}/screenshot_$TIMESTAMP.png"
            notify-send "Screenshot" "Saved to Screenshots/" -t 3000
            ;;
          "Fullscreen (edit)")
            ${pkgs.grim}/bin/grim - | ${pkgs.swappy}/bin/swappy -f -
            ;;
          "Region (edit)")
            ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
            ;;
          "Record fullscreen")
            ${pkgs.wf-recorder}/bin/wf-recorder -f "${recordingDir}/recording_$TIMESTAMP.mp4" &
            notify-send "Recording" "Screen recording started" -t 3000
            ;;
          "Record region")
            ${pkgs.wf-recorder}/bin/wf-recorder -g "$(${pkgs.slurp}/bin/slurp)" -f "${recordingDir}/recording_$TIMESTAMP.mp4" &
            notify-send "Recording" "Region recording started" -t 3000
            ;;
          "Stop recording")
            kill "$RECORDING_PID"
            notify-send "Recording" "Screen recording saved to Recordings/" -t 3000
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
