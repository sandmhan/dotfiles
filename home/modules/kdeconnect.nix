{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome;
  kdeconnectPackage = pkgs.kdePackages.kdeconnect-kde;

  kdeconnectMenu = pkgs.writeShellApplication {
    name = "kdeconnect-menu";
    runtimeInputs = [
      kdeconnectPackage
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.libnotify
      pkgs.rofi
      pkgs.thunar
      pkgs.util-linux
    ];
    text = ''
      notify_error() {
        notify-send -a "KDE Connect" -u critical "KDE Connect" "$1"
      }

      run_action() {
        description="$1"
        shift

        if timeout 20 kdeconnect-cli --device "$device_id" "$@"; then
          notify-send -a "KDE Connect" "KDE Connect" "$description: $device_name"
        else
          notify_error "$description failed for $device_name"
        fi
      }

      timeout 5 kdeconnect-cli --refresh >/dev/null 2>&1 || true
      available="$(timeout 5 kdeconnect-cli --list-available --id-name-only 2>/dev/null || true)"

      if [ -z "$available" ]; then
        choice="$(printf '%s\n' \
          "Open KDE Connect" \
          "Refresh devices" \
          "Cancel" | rofi -dmenu -i -p "KDE Connect: no reachable phone" || true)"

        case "$choice" in
          "Open KDE Connect")
            setsid -f kdeconnect-app >/dev/null 2>&1
            ;;
          "Refresh devices")
            timeout 5 kdeconnect-cli --refresh >/dev/null 2>&1 || true
            sleep 2
            exec "$0"
            ;;
        esac
        exit 0
      fi

      device_count="$(printf '%s\n' "$available" | grep -c .)"
      if [ "$device_count" -eq 1 ]; then
        read -r device_id device_name <<< "$available"
      else
        device_options="$(while IFS=' ' read -r id name; do
          printf '%s\t%s\n' "$name" "$id"
        done <<< "$available")"
        selection="$(printf '%s\n' "$device_options" | rofi -dmenu -i -p "KDE Connect phone" || true)"
        [ -n "$selection" ] || exit 0
        device_name="$(printf '%s' "$selection" | cut -f1)"
        device_id="$(printf '%s' "$selection" | cut -f2)"
      fi

      action="$(printf '%s\n' \
        "Open KDE Connect settings" \
        "Ping phone" \
        "Ring phone" \
        "Send clipboard" \
        "Share text" \
        "Share URL or file" \
        "Browse phone files" \
        "Open SMS" \
        "Refresh devices" | rofi -dmenu -i -p "$device_name" || true)"

      case "$action" in
        "Open KDE Connect settings")
          setsid -f kdeconnect-app >/dev/null 2>&1
          ;;
        "Ping phone")
          run_action "Ping sent" --ping
          ;;
        "Ring phone")
          run_action "Phone is ringing" --ring
          ;;
        "Send clipboard")
          run_action "Clipboard sent" --send-clipboard
          ;;
        "Share text")
          text="$(rofi -dmenu -p "Text to share" || true)"
          [ -n "$text" ] && run_action "Text shared" --share-text "$text"
          ;;
        "Share URL or file")
          target="$(rofi -dmenu -p "URL or absolute file path" || true)"
          [ -n "$target" ] && run_action "Item shared" --share "$target"
          ;;
        "Browse phone files")
          if timeout 20 kdeconnect-cli --device "$device_id" --mount; then
            mount_point="$(timeout 5 kdeconnect-cli --device "$device_id" --get-mount-point 2>/dev/null || true)"
            if [ -n "$mount_point" ]; then
              setsid -f thunar "$mount_point" >/dev/null 2>&1
            else
              notify_error "Phone mounted, but its mount point was not reported"
            fi
          else
            notify_error "Could not mount $device_name"
          fi
          ;;
        "Open SMS")
          setsid -f kdeconnect-sms >/dev/null 2>&1
          ;;
        "Refresh devices")
          timeout 5 kdeconnect-cli --refresh >/dev/null 2>&1 || true
          sleep 2
          exec "$0"
          ;;
      esac
    '';
  };

  kdeconnectStatus = pkgs.writeShellApplication {
    name = "waybar-kdeconnect";
    runtimeInputs = [
      kdeconnectPackage
      pkgs.coreutils
      pkgs.gnused
      pkgs.jq
    ];
    text = ''
      available="$(timeout 5 kdeconnect-cli --list-available --id-name-only 2>/dev/null || true)"

      if [ -n "$available" ]; then
        device_count="$(printf '%s\n' "$available" | sed '/^$/d' | wc -l)"
        device_names="$(printf '%s\n' "$available" | sed -E 's/^[^ ]+ //' | jq -Rsr 'split("\n") | map(select(length > 0)) | join(", ")')"
        class="connected"
        text="󰄡"
        printf -v tooltip 'KDE Connect: %s connected\n%s' "$device_count" "$device_names"
      else
        class="disconnected"
        text="󰄦"
        tooltip="KDE Connect: no reachable phone"
      fi

      jq -cn \
        --arg text "$text" \
        --arg tooltip "$tooltip" \
        --arg class "$class" \
        '{text: $text, tooltip: $tooltip, class: $class}'
    '';
  };
in
{
  config =
    lib.mkIf
      (
        cfg.features.enableKDEConnect
        && cfg.profiles.enableDesktop
        && cfg.features.enableWindowManager
        && cfg.platform.enableLinuxSpecific
      )
      {
        # The custom Waybar/Rofi integration replaces the native tray indicator,
        # avoiding two KDE Connect icons while keeping kdeconnectd user-managed.
        services.kdeconnect = {
          enable = true;
          package = kdeconnectPackage;
          indicator = false;
        };

        home.packages = [ kdeconnectMenu ];

        programs.waybar.settings.mainBar."custom/kdeconnect" = {
          format = "{}";
          return-type = "json";
          interval = 5;
          exec = lib.getExe kdeconnectStatus;
          on-click = lib.getExe kdeconnectMenu;
          on-click-right = "${kdeconnectPackage}/bin/kdeconnect-app";
          tooltip = true;
        };

        wayland.windowManager.sway.config.keybindings."Ctrl+Mod1+K" = "exec ${lib.getExe kdeconnectMenu}";
      };
}
