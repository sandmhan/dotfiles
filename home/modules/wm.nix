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
      autotiling
      nwg-displays # GUI monitor management
      networkmanager
    ];
  };

  programs.waybar = {
    enable = true;
    systemd.enable = false;
    #style = ./waybar.css;
    settings = {

      mainBar = {
        layer = "top";
        position = "top";
        height = 16;
        output = [
          "eDP-1"
          "DP-4"
        ];
        modules-left = [
          "sway/workspaces"
          "sway/mode"
          "sway/window"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "pulseaudio"
          "network"
          "mpd"
          "temperature"
          "memory"
          "cpu"
          "battery"
          "tray"
        ];

        network = {
          interface = "{essid}";
          format = "{ifname}";
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} 󰊗";
          format-disconnected = ""; # An empty format will hide the module
          tooltip-format = "{ifname} via {gwaddr} 󰊗";
          tooltip-format-wifi = "{essid} ({signalStrength}%) ";
          tooltip-format-ethernet = "{ifname} ";
          tooltip-format-disconnected = "Disconnected";
          max-length = 5;
        };

        "sway/window" = {
          icon = true;
          format = "{app_id}";
        };

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon}  {volume}%";
          format-muted = "";
          format-icons = {
            default = [
              ""
              ""
            ];
          };
          scroll-step = 1;
          on-click = "pavucontrol";
          ignored-sinks = [ "Easy Effects Sink" ];
        };

        battery = {
          format = "{icon}{capacity}%";
          format-icons = [
            " "
            " "
            " "
            " "
            " "
          ];
          interval = 60;
          states = {
            warning = 30;
            critical = 15;
          };
        };

        cpu.format = " {usage}%";

        memory = {
          interval = 30;
          format = " {}%";
          max-length = 10;
        };

        tray = {
          icon-size = 24;
          spacing = 8;
        };

        clock = {
          format = " {:%R %x}";
          tooltip-format = "<tt><span>{calendar}</span></tt>";
          calendar.format = {
            days = "<span color='#ecc6d9'><b>{}</b></span>";
            today = "<span color='#ff6699'><b><u>{}</u></b></span>";
          };
        };

        "custom/hello-from-waybar" = {
          format = "hello {}";
          max-length = 40;
          interval = "once";
          exec = pkgs.writeShellScript "hello-from-waybar" ''
            echo "from within waybar"
          '';
        };
      };

      # mainBar = {
      #   layer = "top";
      #   position = "top";
      #   height = 16;
      #   output = [
      #     "eDP-1"
      #     "DP-4"
      #   ];
      #   modules-left = ["sway/workspaces" "mpris"];
      #   modules-center = ["clock"];
      #   modules-right = ["battery" "memory" "cpu" "tray"];

      #   battery = {
      #     format = "{capacity}% {icon}";
      #     format-icons = [" " " " " " " " " "];
      #     interval = 60;
      #     states = {
      #       warning = 30;
      #       critical = 15;
      #     };
      #   };

      #   memory = {
      #     interval = 30;
      #     format = "{}%  ";
      #     max-length = 10;
      #   };

      #   tray = {
      #     icon-size = 24;
      #     spacing = 8;
      #   };

      #   "sway/workspaces" = {
      #     disable-scroll = true;
      #     all-outputs = false;
      #   };

      #   cpu.format = "{usage}% ";

      #   clock = {
      #     format = "   {:%R}";
      #     tooltip-format = "<tt><span>{calendar}</span></tt>";
      #     calendar.format = {
      #       days = "<span color='#ecc6d9'><b>{}</b></span>";
      #       today = "<span color='#ff6699'><b><u>{}</u></b></span>";
      #     };
      #   };
      # };
    };
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
        "${modifier}+P" = "exec ${pkgs.rofi}/bin/rofi -show power-menu:rofi-power-menu ";
        "${modifier}+T" = "exec pkill -SIGUSR1 waybar"; # toggle waybar visibility
        "${modifier}+Shift+T" = "exec theme-switch"; # Rofi theme picker
        "${modifier}+${left}" = "focus left";
        "${modifier}+${right}" = "focus right";
        "${modifier}+${up}" = "focus up";
        "${modifier}+${down}" = "focus down";
        "${modifier}+Shift+Backslash" = "layout toggle split";
        "${modifier}+Shift+G" = "layout toggle splitv tabbed";

        # Quick settings windows
        "${modifier}+N" =
          "exec ${pkgs.alacritty}/bin/alacritty --class floating-nmtui -e ${pkgs.networkmanager}/bin/nmtui";
        "${modifier}+A" =
          "exec ${pkgs.alacritty}/bin/alacritty --class floating-pulsemixer -e ${pkgs.pulsemixer}/bin/pulsemixer";
        "${modifier}+B" =
          "exec ${pkgs.alacritty}/bin/alacritty --class floating-bluetui -e ${pkgs.bluetui}/bin/bluetui";
        "${modifier}+M" =
          "exec ${pkgs.alacritty}/bin/alacritty --class floating-bashmount -e ${pkgs.bashmount}/bin/bashmount";
        "${modifier}+D" = "exec ${pkgs.nwg-displays}/bin/nwg-displays";

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
          { app_id = "vesktop"; }
          { app_id = "legcord"; }
          { app_id = "electron"; }
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

        commands = [
          {
            criteria = {
              app_id = "floating-nmtui";
            };
            command = "floating enable, resize set 800 600";
          }
          {
            criteria = {
              app_id = "floating-pulsemixer";
            };
            command = "floating enable, resize set 800 600";
          }
          {
            criteria = {
              app_id = "floating-bluetui";
            };
            command = "floating enable, resize set 800 600";
          }
          {
            criteria = {
              app_id = "floating-bashmount";
            };
            command = "floating enable, resize set 800 600";
          }
          {
            criteria = {
              app_id = "nwg-displays";
            };
            command = "floating enable, resize set 800 600";
          }
        ];
      };
    };

    extraConfig = "";

  };
}
