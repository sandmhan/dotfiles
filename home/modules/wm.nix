# based off https://git.sr.ht/~hervyqa/swayhome/tree/HEAD/item/home/wayland/sway.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHome;
  legcordPatched = pkgs.callPackage ../packages/legcord { };

  # Navigation
  left = "h";
  down = "j";
  up = "k";
  right = "l";
  modifier = "Mod1";

  glassDisplay = pkgs.writeShellApplication {
    name = "glass-display";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.sway
    ];
    text = ''
      output="HEADLESS-1"
      workspaces=(7 8 9)

      get_outputs() {
        swaymsg --raw --type get_outputs
      }

      output_is_known() {
        get_outputs | jq --exit-status --arg output "$output" \
          '.[] | select(.name == $output)' >/dev/null
      }

      output_is_active() {
        get_outputs | jq --exit-status --arg output "$output" \
          '.[] | select(.name == $output and .active)' >/dev/null
      }

      output_is_configured() {
        get_outputs | jq --exit-status --arg output "$output" '
          .[] | select(
            .name == $output and
            .active and
            .current_mode.width == 640 and
            .current_mode.height == 360 and
            .current_mode.refresh == 60000 and
            .scale == 1
          )
        ' >/dev/null
      }

      focused_context() {
        swaymsg --raw --type get_workspaces |
          jq --raw-output '.[] | select(.focused) | [.output, .name] | @tsv'
      }

      fallback_output() {
        get_outputs | jq --raw-output --arg output "$output" '
          ([.[] | select(.active and .name != $output and .focused)][0].name) //
          ([.[] | select(.active and .name != $output)][0].name) //
          empty
        '
      }

      move_glass_workspaces() {
        local destination="$1"
        local workspace
        for workspace in "''${workspaces[@]}"; do
          swaymsg --quiet workspace number "$workspace" || return 1
          swaymsg --quiet move workspace to output "$destination" || return 1
        done
      }

      restore_focus() {
        local output_name="$1"
        local workspace="$2"
        local glass_workspace
        for glass_workspace in "''${workspaces[@]}"; do
          if [[ "$workspace" == "$glass_workspace" ]]; then
            workspace=""
            break
          fi
        done
        swaymsg --quiet focus output "$output_name" || return 1
        if [[ -n "$workspace" ]]; then
          swaymsg --quiet workspace "$workspace" || return 1
        fi
      }

      enable_display() {
        local context
        local previous_output
        local previous_workspace
        context=$(focused_context)
        IFS=$'\t' read -r previous_output previous_workspace <<< "$context"

        if output_is_known; then
          if ! output_is_active; then
            swaymsg --quiet "output $output enable"
          fi
        else
          swaymsg --quiet create_output
        fi

        for _ in {1..20}; do
          if output_is_active; then
            swaymsg --quiet "output $output enable mode 640x360@60Hz scale 1 power on"
            if ! output_is_configured; then
              restore_focus "$previous_output" "$previous_workspace" || true
              printf '%s\n' "Failed to configure $output at 640x360@60Hz scale 1" >&2
              return 1
            fi
            if ! move_glass_workspaces "$output"; then
              restore_focus "$previous_output" "$previous_workspace" || true
              printf '%s\n' "Failed to move all Glass workspaces to $output" >&2
              return 1
            fi
            if ! restore_focus "$previous_output" "$previous_workspace"; then
              printf '%s\n' "Glass workspaces moved, but previous focus could not be restored" >&2
              return 1
            fi
            printf '%s\n' "$output enabled for workspaces 7, 8, and 9"
            return 0
          fi
          sleep 0.1
        done

        printf '%s\n' "Failed to enable $output" >&2
        return 1
      }

      disable_display() {
        local context
        local destination
        local previous_output
        local previous_workspace
        local restore_output

        if ! output_is_active; then
          printf '%s\n' "$output is already disabled"
          return 0
        fi

        context=$(focused_context)
        IFS=$'\t' read -r previous_output previous_workspace <<< "$context"
        destination=$(fallback_output)
        if [[ -z "$destination" ]]; then
          printf '%s\n' "Cannot disable $output without another active output" >&2
          return 1
        fi

        if ! move_glass_workspaces "$destination"; then
          restore_focus "$previous_output" "$previous_workspace" || true
          printf '%s\n' "Failed to move all Glass workspaces to $destination" >&2
          return 1
        fi

        restore_output="$previous_output"
        if [[ "$restore_output" == "$output" ]]; then
          restore_output="$destination"
        fi
        if ! restore_focus "$restore_output" "$previous_workspace"; then
          printf '%s\n' "Glass workspaces moved, but previous focus could not be restored" >&2
          return 1
        fi

        swaymsg --quiet output "$output" disable
        printf '%s\n' "$output disabled; workspaces 7, 8, and 9 moved to $destination"
      }

      show_status() {
        if output_is_active; then
          get_outputs | jq --raw-output --arg output "$output" '
            .[] | select(.name == $output) |
            "\(.name) is enabled at \(.current_mode.width)x\(.current_mode.height)@\(.current_mode.refresh / 1000)Hz scale \(.scale)"
          '
          swaymsg --raw --type get_workspaces |
            jq --raw-output --arg output "$output" '
              [.[] | select(.output == $output) | .name] |
              "workspaces on display: " + (if length == 0 then "none" else join(", ") end)
            '
        else
          printf '%s\n' "$output is disabled"
        fi
      }

      case "''${1:-toggle}" in
        on)
          enable_display
          ;;
        off)
          disable_display
          ;;
        toggle)
          if output_is_active; then
            disable_display
          else
            enable_display
          fi
          ;;
        status)
          show_status
          ;;
        *)
          printf '%s\n' "Usage: glass-display [on|off|toggle|status]" >&2
          exit 2
          ;;
      esac
    '';
  };

  glassVnc = pkgs.writeShellApplication {
    name = "glass-vnc";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssl
      pkgs.systemd
      pkgs.wayvnc
    ];
    text = ''
      unit="glass-vnc.service"
      output="HEADLESS-1"
      listen_address="10.0.0.3:35900"
      config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc-glass"
      password_file="$config_dir/password"
      runtime_dir="''${XDG_RUNTIME_DIR:-}/wayvnc-glass"
      config_file="$runtime_dir/wayvnc.ini"
      certificate_file="$runtime_dir/certificate.pem"
      private_key_file="$runtime_dir/private-key.pem"
      control_socket="''${XDG_RUNTIME_DIR:-}/wayvnc-glass-wifi.ctl"

      usage() {
        printf '%s\n' "Usage: glass-vnc [start|stop|restart|status]"
      }

      validate_password() {
        local metadata
        local password_fd
        local user_id

        if [[ ! -d "$config_dir" || -L "$config_dir" || ! -O "$config_dir" ]]; then
          printf '%s\n' "Glass VNC credential directory is unavailable or unsafe: $config_dir" >&2
          printf '%s\n' "Restore the password already enrolled on Glass; do not generate a replacement while Glass has no input path." >&2
          return 1
        fi
        if [[ "$(stat --format='%a' "$config_dir")" != 700 ]]; then
          printf '%s\n' "Glass VNC credential directory must have mode 0700: $config_dir" >&2
          return 1
        fi
        if [[ -L "$password_file" ]] || ! exec {password_fd}<"$password_file"; then
          printf '%s\n' "Glass VNC credential is unavailable or unsafe: $password_file" >&2
          printf '%s\n' "Restore the password already enrolled on Glass; do not generate a replacement while Glass has no input path." >&2
          return 1
        fi

        user_id=$(id --user)
        metadata=$(stat --dereference --format='%F:%u:%a' "/proc/$$/fd/$password_fd")
        if [[ "$metadata" != "regular file:$user_id:600" ]]; then
          exec {password_fd}<&-
          printf '%s\n' "Glass VNC credential must be a user-owned regular file with mode 0600: $password_file" >&2
          return 1
        fi
        password=$(cat <&"$password_fd")
        exec {password_fd}<&-
        if [[ ! "$password" =~ ^[A-Za-z0-9+/]{8}$ ]]; then
          printf '%s\n' "Glass VNC credential must contain exactly eight Base64 characters." >&2
          return 1
        fi
      }

      validate_runtime() {
        if [[ -z "''${XDG_RUNTIME_DIR:-}" || ! -d "$XDG_RUNTIME_DIR" || -L "$XDG_RUNTIME_DIR" || ! -O "$XDG_RUNTIME_DIR" ]]; then
          printf '%s\n' "XDG_RUNTIME_DIR is unavailable or unsafe." >&2
          return 1
        fi
        install -d -m 0700 "$runtime_dir"
      }

      prepare_runtime() {
        validate_password
        validate_runtime
        if [[ -S "$control_socket" ]] && wayvncctl --socket "$control_socket" version >/dev/null 2>&1; then
          printf '%s\n' "Another WayVNC process already owns $control_socket" >&2
          return 1
        fi
        rm -f "$control_socket"
        cleanup_runtime
        ${glassDisplay}/bin/glass-display on

        umask 077
        openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
          -subj '/CN=gaia-glass-wayvnc' \
          -keyout "$private_key_file" \
          -out "$certificate_file" \
          >/dev/null 2>&1
        chmod 0600 "$private_key_file"

        config_tmp=$(mktemp "$runtime_dir/.wayvnc.ini.XXXXXX")
        {
          printf '%s\n' \
            'enable_auth=true' \
            'allow_broken_crypto=true' \
            'relax_encryption=true' \
            "password=$password" \
            "certificate_file=$certificate_file" \
            "private_key_file=$private_key_file"
        } > "$config_tmp"
        chmod 0600 "$config_tmp"
        mv -f "$config_tmp" "$config_file"
        config_tmp=""
      }

      cleanup_runtime() {
        rm -f "''${config_tmp:-}" "$config_file" "$certificate_file" "$private_key_file"
        if [[ "''${owns_control_socket:-false}" == true ]]; then
          rm -f "$control_socket"
        fi
      }

      run_server() {
        config_tmp=""
        owns_control_socket=false
        trap cleanup_runtime EXIT
        prepare_runtime
        owns_control_socket=true
        wayvnc \
          --config "$config_file" \
          --disable-input \
          --output "$output" \
          --max-fps=15 \
          --socket "$control_socket" \
          --log-level=info \
          "$listen_address" &
        wayvnc_pid=$!
        terminate() {
          kill "$wayvnc_pid" 2>/dev/null || true
        }
        trap terminate INT TERM HUP
        wait "$wayvnc_pid"
      }

      wait_until_ready() {
        for _ in {1..50}; do
          if systemctl --user is-active --quiet "$unit" && \
            wayvncctl --socket "$control_socket" version >/dev/null 2>&1; then
            return 0
          fi
          sleep 0.1
        done
        printf '%s\n' "$unit did not become ready" >&2
        systemctl --user status --no-pager "$unit" >&2 || true
        return 1
      }

      show_status() {
        if systemctl --user is-active --quiet "$unit"; then
          printf '%s\n' "$unit is active"
          wayvncctl --socket "$control_socket" client-list || true
        else
          printf '%s\n' "$unit is inactive"
        fi
        ${glassDisplay}/bin/glass-display status
      }

      case "''${1:-status}" in
        start)
          validate_password
          systemctl --user start "$unit"
          wait_until_ready
          ;;
        stop)
          systemctl --user stop "$unit"
          ;;
        restart)
          validate_password
          systemctl --user restart "$unit"
          wait_until_ready
          ;;
        status)
          show_status
          ;;
        run)
          run_server
          ;;
        *)
          usage >&2
          exit 2
          ;;
      esac
    '';
  };

  # Legcord can keep a main Electron process alive after its renderer dies. Later
  # launches then connect to that stale singleton and only display a blank window.
  legcordLauncher = pkgs.writeShellApplication {
    name = "legcord-launch";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.glibc.bin
      pkgs.jq
      pkgs.procps
      pkgs.sway
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

      legcord_has_window() {
        local main_pid window_tree
        window_tree="$(swaymsg --raw --type get_tree 2>/dev/null)" || return 1

        while IFS= read -r main_pid; do
          if jq --exit-status --argjson main_pid "$main_pid" \
            '.. | objects | select(.pid? == $main_pid)' \
            <<< "$window_tree" >/dev/null; then
            return 0
          fi
        done < <(legcord_main_pids)
        return 1
      }

      wait_for_window() {
        local attempts="$1"
        local attempt
        for ((attempt = 0; attempt < attempts; attempt++)); do
          if legcord_has_window; then
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
      # a Sway window for this user-data directory and should receive normal Electron
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
        if wait_for_window 50; then
          flock --unlock 9
          exec ${lib.getExe legcordPatched} "$@" 9>&-
        fi
        stop_stale_legcord
      fi

      cleanup_singleton
      ${lib.getExe legcordPatched} "$@" 9>&- &
      legcord_pid=$!

      if wait_for_window 300; then
        flock --unlock 9
        wait "$legcord_pid"
        exit $?
      fi

      kill "$legcord_pid" 2>/dev/null || true
      stop_stale_legcord
      cleanup_singleton
      flock --unlock 9
      wait "$legcord_pid" 2>/dev/null || true
      printf '%s\n' "Legcord failed to create a window within 30 seconds" >&2
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
      ++ [
        glassDisplay
        glassVnc
      ]
      ++ lib.optionals cfg.profiles.enableSocial [ legcordLauncher ];
  };

  systemd.user.services.glass-vnc = {
    Unit = {
      Description = "Source-restricted view-only WayVNC display for Google Glass";
      After = [ config.wayland.systemd.target ];
      PartOf = [ config.wayland.systemd.target ];
      ConditionEnvironment = "SWAYSOCK";
    };
    Service = {
      ExecStart = "${glassVnc}/bin/glass-vnc run";
      Restart = "no";
    };
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

      # Route the final three workspaces to the Google Glass headless output
      # whenever it is enabled by the glass-display helper.
      workspaceOutputAssign =
        map
          (workspace: {
            workspace = toString workspace;
            output = "HEADLESS-1";
          })
          [
            7
            8
            9
          ];

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
