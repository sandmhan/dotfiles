# based off https://git.sr.ht/~hervyqa/swayhome/tree/HEAD/item/home/wayland/sway.nix
{
  pkgs,
  lib,
  ...
}:
let
  # Navigation
  left = "h";
  down = "j";
  up = "k";
  right = "l";
  modifier = "Mod1";

in
{
  home = {
    packages = with pkgs; [
      rofi
      waybar
      autotiling
    ];
  };

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    config = {
      inherit modifier;
      inherit left;
      inherit down;
      inherit up;
      inherit right;

      bars = [ ];

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
        "${modifier}+R" =
          "exec ${pkgs.rofi}/bin/rofi -show combi -modes combi -combi-modes 'window,drun,run' ";
        "${modifier}+B" = "exec pkill -SIGUSR1 waybar"; # only works if waybar has already been started
        "Ctrl+Mod1+M" = "mode move";
        "Ctrl+Mod1+R" = "mode resize";
        "${modifier}+Shift+Backslash" = "layout toggle split";
        "${modifier}+Shift+G" = "layout toggle splitv tabbed";
      }
      // builtins.listToAttrs (
        builtins.concatMap
          (workspace: [
            {
              name = "${modifier}+${toString workspace}";
              value = "workspace number ${toString workspace}";
            }
            {
              name = "${modifier}+Shift+${toString workspace}";
              value = "move container to workspace number ${toString workspace}; workspace ${toString workspace}";
            }
          ])
          [
            1
            2
            3
            4
            5
            6
            7
            8
            9
          ]
      );

      modes = {
        move = {
          Comma = "move container to workspace prev; workspace prev";
          Escape = "mode default";
          Period = "move container to workspace next; workspace next";
          S = "move scratchpad";
        }
        // builtins.listToAttrs (
          builtins.concatMap
            (workspace: [
              {
                name = toString workspace;
                value = "move container to workspace number ${toString workspace}; workspace ${toString workspace}";
              }
            ])
            [
              1
              2
              3
              4
              5
              6
              7
              8
              9
            ]
        ); # improve to add directional focus and move hotkeys

        resize = {
          Escape = "mode default";
          left = "resize shrink width 10 px";
          down = "resize grow height 10 px";
          up = "resize shrink height 10 px";
          right = "resize grow width 10 px";
        };
      };

      startup = [
        { command = lib.getExe pkgs.autotiling; }
        { command = lib.getExe pkgs.waybar; }
      ];

      window = {
        titlebar = false;
      };

    };

    extraConfig = '''';

  };
}
