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
      nwg-displays # GUI monitor management
      networkmanager
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

      # Currently have waybar set to turn on upon startup. Not sure if it should be here instead
      bars = [
        {
          command = lib.getExe pkgs.waybar;
        }
      ];

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
        "${modifier}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
        "${modifier}+C" = "kill";
        "${modifier}+R" =
          "exec ${pkgs.rofi}/bin/rofi -show combi -modes combi -combi-modes 'window,drun,run' ";
        "${modifier}+T" = "exec pkill -SIGUSR1 waybar"; # only works if waybar has already been started
        "${modifier}+${left}" = "focus left";
        "${modifier}+${right}" = "focus right";
        "${modifier}+${up}" = "focus up";
        "${modifier}+${down}" = "focus down";
        "${modifier}+Shift+Backslash" = "layout toggle split";
        "${modifier}+Shift+G" = "layout toggle splitv tabbed";

        ## Modes
        "Ctrl+${modifier}+M" = "mode move";
        "Ctrl+${modifier}+R" = "mode resize";
        "Ctrl+${modifier}+S" = "mode session";
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
          Escape = "mode default";
          Comma = "move container to workspace prev; workspace prev";
          Period = "move container to workspace next; workspace next";
          "${left}" = "move left";
          "${right}" = "move right";
          "${up}" = "move up";
          "${down}" = "move down";
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
          ${left} = "resize shrink width 10 px";
          ${down} = "resize grow height 10 px";
          ${up} = "resize shrink height 10 px";
          ${right} = "resize grow width 10 px";
        };

         session = {
                  # Session = launch:
                  # [h]ibernate [p]oweroff [r]eboot
                  # [s]uspend [l]ockscreen log[o]ut
                  Escape = "mode default";
                  Return = "mode default";
                  "h" = "exec ${pkgs.systemd}/bin/systemctl hibernate, mode default";
                  "p" = "exec ${pkgs.systemd}/bin/systemctl poweroff, mode default";
                  "r" = "exec ${pkgs.systemd}/bin/systemctl reboot, mode default";
                  "s" = "exec ${pkgs.systemd}/bin/systemctl suspend, mode default";
                  "l" = "exec ${pkgs.swaylock}/bin/swaylock, mode default";
                  "o" = "exec ${pkgs.sway}/bin/swaymsg exit, mode default";
                };
      };

      startup = [
        { command = lib.getExe pkgs.autotiling; }
        { command = lib.getExe pkgs.alacritty; }
        #{ command = lib.getExe pkgs.qutebrowser; }
        { command = lib.getExe pkgs.legcord; }
      ];

      assigns = {
        "1" = [
          # Terminal
          { app_id = "Alacritty"; }
        ];
        "2" = [
          # Browser
          { app_id = ".*qutebrowser"; }
          { app_id = "firefox"; }
        ];
        "3" = [
          # Entertainment
          { class = "discord"; }
          { class = "vesktop"; }
          { class = "legcord"; }
        ];
        "4" = [
          # Office
          { app_id = "libreoffice-*"; }
        ];
        "5" = [
          # Secrets
          { app_id = "Bitwarden"; }
        ];
      };

      window = {
        titlebar = false;
      };

    };

    extraConfig = '''';

  };
}
