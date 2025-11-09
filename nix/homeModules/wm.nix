# based off https://git.sr.ht/~hervyqa/swayhome/tree/HEAD/item/home/wayland/sway.nix
{
  pkgs,
  ...
}:
let
  # Navigation
  left = "h";
  down = "j";
  up = "k";
  right = "l";
  modifier = "Control";

in {
  home = {
    packages =
      with pkgs;
      [
        rofi
      ];
    };

  wayland.windowManager.sway = {
    enable = true;
    config = {
      inherit modifier;
      focus = {
        followMouse = false;
        newWindow = "focus";
      };

      defaultWorkspace = "workspace number 1";
      input = {
        "type:touchpad" = {
          click_method = "clickfinger";
          dwt = "enabled";
          natural_scroll = "enabled";
          scroll_method = "two_finger";
          tap = "enabled";
          tap_button_map = "lrm";
        };
        "type:keyboard" = {
          xkb_layout = "us";
        };
      };

      keybindings = {
        "${modifier}+T" = "exec ${pkgs.alacritty}/bin/alacritty";
        "${modifier}+C" = "kill";
        "${modifier}+R" = "exec ${pkgs.rofi}/bin/rofi -show combi -modes combi -combi-modes 'window,drun,run' ";
      }
      //
      builtins.listToAttrs (
        builtins.concatMap (workspace: [
          {
            name = "${modifier}+${toString workspace}";
            value = "workspace number ${toString workspace}";
          }
          {
            name = "${modifier}+Shift+${toString workspace}";
            value = "move container to workspace number ${toString workspace}; workspace ${toString workspace}";
          }
        ]) [1 2 3 4 5 6 7 8 9]
      );
    };
  };
}

