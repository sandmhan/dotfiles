# based off https://git.sr.ht/~hervyqa/swayhome/tree/HEAD/item/home/wayland/sway.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHome;

  # Navigation
  left = "h";
  down = "j";
  up = "k";
  right = "l";
  modifier = "Mod1";

  # Legcord can keep a main Electron process alive after its renderer dies. Later
  # launches then connect to that stale singleton and only display a blank window.
  legcordLauncher = pkgs.writeShellApplication {
    name = "legcord-launch";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.glibc.bin
      pkgs.procps
      pkgs.util-linux
    ];
    text = ''
      if [[ "''${1:-}" == "--wait-for-network" ]]; then
        shift
        network_ready=false
        deadline=$((SECONDS + 30))
        while (( SECONDS < deadline )); do
          if timeout 2 getent ahosts discord.com >/dev/null 2>&1; then
            network_ready=true
            break
          fi
          sleep 1
        done

        if [[ "$network_ready" != true ]]; then
          printf '%s\n' "Legcord startup skipped: discord.com did not resolve within 30 seconds" >&2
          exit 1
        fi
      fi

      runtime_dir="''${XDG_RUNTIME_DIR:-}"
      config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/legcord"
      app_pattern='/share/lib/legcord/resources/app[.]asar'
      crashpad_pattern='chrome_crashpad_handler'

      for argument in "$@"; do
        case "$argument" in
          --user-data-dir | --user-data-dir=*)
            printf '%s\n' "legcord-launch does not support overriding the Legcord user-data directory" >&2
            exit 2
            ;;
        esac
      done

      if [[ -z "$runtime_dir" || ! -d "$runtime_dir" || -L "$runtime_dir" || ! -O "$runtime_dir" ]]; then
        printf '%s\n' "Legcord startup skipped: XDG_RUNTIME_DIR is unavailable or unsafe" >&2
        exit 1
      fi
      runtime_mode=$(stat --format='%a' "$runtime_dir")
      if (( (8#$runtime_mode & 077) != 0 )); then
        printf '%s\n' "Legcord startup skipped: XDG_RUNTIME_DIR permissions are too broad" >&2
        exit 1
      fi

      legcord_main_pids() {
        local argument
        local main_pid
        local previous_argument
        local user_data_dir
        while IFS= read -r main_pid; do
          [[ -r "/proc/$main_pid/cmdline" ]] || continue
          previous_argument=""
          user_data_dir=""
          while IFS= read -r -d "" argument; do
            if [[ "$previous_argument" == "--user-data-dir" ]]; then
              user_data_dir="$argument"
              break
            fi
            case "$argument" in
              --user-data-dir=*)
                user_data_dir="''${argument#--user-data-dir=}"
                break
                ;;
            esac
            previous_argument="$argument"
          done < "/proc/$main_pid/cmdline"
          if [[ -z "$user_data_dir" || "$user_data_dir" == "$config_dir" ]]; then
            printf '%s\n' "$main_pid"
          fi
        done < <(pgrep --uid "$UID" --full -- "$app_pattern" || true)
      }

      legcord_has_renderer() {
        local renderer_pid
        while IFS= read -r renderer_pid; do
          if grep --fixed-strings --line-regexp --null-data --quiet \
            -- "--user-data-dir=$config_dir" "/proc/$renderer_pid/cmdline" 2>/dev/null; then
            return 0
          fi
        done < <(pgrep --uid "$UID" --full -- '[ -]-type=renderer' || true)
        return 1
      }

      wait_for_renderer() {
        local attempts="$1"
        local attempt
        for ((attempt = 0; attempt < attempts; attempt++)); do
          if legcord_has_renderer; then
            return 0
          fi
          sleep 0.1
        done
        return 1
      }

      stop_stale_legcord() {
        local -a main_pids
        mapfile -t main_pids < <(legcord_main_pids)
        if (( ''${#main_pids[@]} > 0 )); then
          kill -- "''${main_pids[@]}" 2>/dev/null || true
        fi
        for _ in {1..50}; do
          mapfile -t main_pids < <(legcord_main_pids)
          if (( ''${#main_pids[@]} == 0 )); then
            break
          fi
          sleep 0.1
        done
        mapfile -t main_pids < <(legcord_main_pids)
        if (( ''${#main_pids[@]} > 0 )); then
          kill -KILL -- "''${main_pids[@]}" 2>/dev/null || true
        fi
        while IFS= read -r crashpad_pid; do
          if grep --fixed-strings --line-regexp --null-data --quiet \
            -- "--database=$config_dir/Crashpad" "/proc/$crashpad_pid/cmdline" 2>/dev/null; then
            kill -- "$crashpad_pid" 2>/dev/null || true
          fi
        done < <(pgrep --uid "$UID" --full -- "$crashpad_pattern" || true)
      }

      cleanup_singleton() {
        rm -f \
          "$config_dir/SingletonCookie" \
          "$config_dir/SingletonLock" \
          "$config_dir/SingletonSocket"
      }

      # Serialize stale detection and replacement startup. A healthy instance has
      # a renderer for this user-data directory and should receive normal Electron
      # singleton forwarding instead of being restarted.
      lock_file="$runtime_dir/legcord-launch.lock"
      if [[ -L "$lock_file" || ( -e "$lock_file" && ! -f "$lock_file" ) ]]; then
        printf '%s\n' "Legcord startup skipped: unsafe launcher lock file" >&2
        exit 1
      fi
      umask 077
      exec 9>"$lock_file"
      if ! flock --timeout 60 9; then
        printf '%s\n' "Legcord startup skipped: another launcher did not release its lock" >&2
        exit 1
      fi

      if [[ -n "$(legcord_main_pids)" ]]; then
        if wait_for_renderer 50; then
          flock --unlock 9
          exec ${lib.getExe pkgs.legcord} "$@" 9>&-
        fi
        stop_stale_legcord
      fi

      cleanup_singleton
      ${lib.getExe pkgs.legcord} "$@" 9>&- &
      legcord_pid=$!

      if wait_for_renderer 300; then
        flock --unlock 9
        wait "$legcord_pid"
        exit $?
      fi

      kill "$legcord_pid" 2>/dev/null || true
      stop_stale_legcord
      cleanup_singleton
      flock --unlock 9
      wait "$legcord_pid" 2>/dev/null || true
      printf '%s\n' "Legcord failed to create a renderer within 30 seconds" >&2
      exit 1
    '';
  };

in
{
  home = {
    packages =
      (with pkgs; [
        autotiling
        nwg-displays # GUI monitor management
        networkmanager
      ])
      ++ lib.optionals cfg.profiles.enableSocial [ legcordLauncher ];
  };

  # Override the package-provided entry so every explicit open recovers from a
  # stale Electron singleton instead of forwarding to it.
  xdg.dataFile."applications/legcord.desktop" = lib.mkIf cfg.profiles.enableSocial {
    text = ''
      [Desktop Entry]
      Categories=Network;InstantMessaging;Chat
      Comment=Lightweight, alternative desktop client for Discord
      Exec=${lib.getExe legcordLauncher} %U
      GenericName=Internet Messenger
      Icon=legcord
      MimeType=x-scheme-handler/discord;
      Name=Legcord
      StartupWMClass=Legcord
      Terminal=false
      Type=Application
      Version=1.5
    '';
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
          "mpd"
          "temperature"
          "memory"
          "cpu"
          "battery"
          "network"
        ]
        ++ lib.optionals cfg.features.enableKDEConnect [
          "custom/kdeconnect"
        ]
        ++ [
          "custom/tailscale"
        ];

        network = {
          interval = 5;
          format-wifi = "{icon} {bandwidthDownBytes}";
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          format-ethernet = "󰈀 {bandwidthDownBytes}";
          format-disconnected = "󰤭";
          tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}\n {bandwidthUpBytes}  {bandwidthDownBytes}";
          tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}\n {bandwidthUpBytes}  {bandwidthDownBytes}";
          tooltip-format-disconnected = "Disconnected";
          min-length = 12;
          align = 0;
          on-click = "${pkgs.alacritty}/bin/alacritty --class floating-nmtui -e ${pkgs.networkmanager}/bin/nmtui";
        };

        "custom/tailscale" = {
          format = "{}";
          interval = 5;
          exec = pkgs.writeShellScript "waybar-tailscale" ''
            if ${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -e '.Self.Online' >/dev/null 2>&1; then
              echo '{"text": "󰖂", "tooltip": "Tailscale: connected", "class": "connected"}'
            else
              echo '{"text": "󰖂", "tooltip": "Tailscale: disconnected", "class": "disconnected"}'
            fi
          '';
          return-type = "json";
          on-click = pkgs.writeShellScript "waybar-tailscale-toggle" ''
            if ${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -e '.Self.Online' >/dev/null 2>&1; then
              sudo ${pkgs.tailscale}/bin/tailscale down
            else
              sudo ${pkgs.tailscale}/bin/tailscale up
            fi
          '';
        };

        "sway/window" = {
          icon = true;
          format = "{app_id}";
        };

        "sway/workspaces" = {
          disable-scroll = true;
          # Keep virtual/headless outputs from contributing empty workspaces to
          # the bar on a physical display.
          all-outputs = false;
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

  # Blank idle displays without suspending the system so long-running local
  # jobs and agent sessions continue to make progress. Input restores output.
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 600;
        command = "${pkgs.sway}/bin/swaymsg 'output * power off'";
        resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * power on'";
      }
    ];
  };

  # Keep the inactive Hyprland module on its current configuration format and
  # avoid relying on a state-version-dependent Home Manager default.
  wayland.windowManager.hyprland.configType = "hyprlang";

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    config = {
      inherit modifier;
      inherit left;
      inherit down;
      inherit up;
      inherit right;

      # No sway-managed bars — waybar runs as a standalone layer-shell
      # process via startup so swaymsg reload doesn't kill/restart it.
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
        "${modifier}+Shift+Space" = "floating toggle";
        "${modifier}+Space" = "focus mode_toggle";

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
        { command = lib.getExe pkgs.waybar; }
        { command = lib.getExe pkgs.alacritty; }
        #{ command = lib.getExe pkgs.qutebrowser; }
      ]
      ++ lib.optionals cfg.profiles.enableSocial [
        { command = "${lib.getExe legcordLauncher} --wait-for-network"; }
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
          { app_id = "zen.*"; }
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

    # Include runtime-switchable window colors (overrides Stylix's build-time colors).
    # Sway processes config top-to-bottom; this include at the end always wins.
    extraConfig = ''
      include ~/.local/share/active-sway.conf
    '';

  };
}
