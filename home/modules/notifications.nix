{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome;
  swaync = pkgs.swaynotificationcenter;

  gaiaDesktopEventNotifier = pkgs.writeShellScript "gaia-desktop-event-notifier" ''
    set -uo pipefail

    notify_status() {
      ${pkgs.libnotify}/bin/notify-send \
        --app-name="Gaia System" \
        --urgency=low \
        --expire-time=3500 \
        --icon="$1" \
        "$2" "$3" || true
    }

    monitor_power() {
      local power_path=/sys/class/power_supply/ACAD/online
      local previous current

      if [ ! -r "$power_path" ]; then
        while ${pkgs.coreutils}/bin/sleep 3600; do :; done
      fi

      previous=$(<"$power_path")
      while ${pkgs.coreutils}/bin/sleep 2; do
        current=$(<"$power_path")
        [ "$current" = "$previous" ] && continue

        if [ "$current" = 1 ]; then
          notify_status "battery-good-charging-symbolic" \
            "Power connected" "Gaia is using the balanced power profile"
        else
          notify_status "battery-symbolic" \
            "Running on battery" "Gaia is using the power-saver profile"
        fi
        previous="$current"
      done
    }

    monitor_battery() {
      local capacity_path=/sys/class/power_supply/BAT1/capacity
      local status_path=/sys/class/power_supply/BAT1/status
      local alert_level=0 capacity status

      if [ ! -r "$capacity_path" ] || [ ! -r "$status_path" ]; then
        while ${pkgs.coreutils}/bin/sleep 3600; do :; done
      fi

      while ${pkgs.coreutils}/bin/sleep 60; do
        capacity=$(<"$capacity_path")
        status=$(<"$status_path")

        if [ "$status" != Discharging ] || [ "$capacity" -gt 20 ]; then
          alert_level=0
        elif [ "$capacity" -le 5 ] && [ "$alert_level" -lt 2 ]; then
          ${pkgs.libnotify}/bin/notify-send \
            --app-name="Gaia System" \
            --urgency=critical \
            --expire-time=0 \
            --icon="battery-empty-symbolic" \
            "Battery critically low" \
            "''${capacity}% remaining; connect power now" || true
          alert_level=2
        elif [ "$capacity" -le 15 ] && [ "$alert_level" -lt 1 ]; then
          ${pkgs.libnotify}/bin/notify-send \
            --app-name="Gaia System" \
            --urgency=normal \
            --expire-time=10000 \
            --icon="battery-caution-symbolic" \
            "Battery low" \
            "''${capacity}% remaining" || true
          alert_level=1
        fi
      done
    }

    active_wifi_connection() {
      ${pkgs.coreutils}/bin/timeout 3s \
        ${pkgs.networkmanager}/bin/nmcli --terse --fields NAME,TYPE connection show --active \
        | ${pkgs.gnused}/bin/sed -n 's/:802-11-wireless$//p' \
        | ${pkgs.coreutils}/bin/head -n 1
    }

    monitor_wifi() {
      local previous current

      previous=$(active_wifi_connection 2>/dev/null || true)
      while ${pkgs.coreutils}/bin/sleep 5; do
        current=$(active_wifi_connection 2>/dev/null || true)
        if [ -n "$current" ] && [ "$current" != "$previous" ]; then
          notify_status "network-wireless-symbolic" \
            "Wi-Fi connected" "$current"
        fi
        previous="$current"
      done
    }

    connected_bluetooth_devices() {
      ${pkgs.coreutils}/bin/timeout 3s \
        ${pkgs.bluez}/bin/bluetoothctl devices Connected \
        | ${pkgs.gnused}/bin/sed -n 's/^Device \([^ ]*\) \(.*\)$/\1|\2/p'
    }

    monitor_bluetooth() {
      local previous current address name

      previous=$(connected_bluetooth_devices 2>/dev/null || true)
      while ${pkgs.coreutils}/bin/sleep 5; do
        current=$(connected_bluetooth_devices 2>/dev/null || true)
        while IFS='|' read -r address name; do
          [ -n "$address" ] || continue
          if ! ${pkgs.gnugrep}/bin/grep --fixed-strings --line-regexp \
            --quiet "$address|$name" <<< "$previous"; then
            notify_status "bluetooth-active-symbolic" \
              "Bluetooth connected" "$name"
          fi
        done <<< "$current"
        previous="$current"
      done
    }

    monitor_power &
    monitor_battery &
    monitor_wifi &
    monitor_bluetooth &
    wait
  '';
in
{
  config = lib.mkIf cfg.features.enableWindowManager {
    services.swaync = {
      enable = true;
      settings = {
        "$schema" = "${swaync}/etc/xdg/swaync/configSchema.json";
        ignore-gtk-theme = true;
        positionX = "right";
        positionY = "top";
        layer = "overlay";
        control-center-layer = "overlay";
        layer-shell = true;
        control-center-margin-top = 8;
        control-center-margin-bottom = 8;
        control-center-margin-right = 8;
        control-center-margin-left = 8;
        notification-2fa-action = true;
        notification-inline-replies = true;
        timeout = 6;
        timeout-low = 3;
        timeout-critical = 0;
        fit-to-screen = true;
        relative-timestamps = true;
        control-center-width = 420;
        notification-window-width = 400;
        keyboard-shortcuts = true;
        notification-grouping = true;
        image-visibility = "when-available";
        transition-time = 150;
        hide-on-clear = false;
        hide-on-action = true;
        text-empty = "No notifications";
        script-fail-notify = false;
        widgets = [
          "title"
          "dnd"
          "notifications"
        ];
        widget-config = {
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear all";
          };
          dnd.text = "Do not disturb";
          notifications.vexpand = true;
        };
      };
    };

    programs.waybar.settings.mainBar = {
      modules-right = lib.mkBefore [ "custom/notification" ];
      "custom/notification" = {
        tooltip = true;
        format = "{icon}";
        format-icons = {
          notification = "󱅫";
          none = "󰂜";
          dnd-notification = "󰂠";
          dnd-none = "󰪓";
          inhibited-notification = "󰂛";
          inhibited-none = "󰪑";
          dnd-inhibited-notification = "󰂛";
          dnd-inhibited-none = "󰪑";
        };
        return-type = "json";
        exec-if = "${swaync}/bin/swaync-client --version";
        exec = "${swaync}/bin/swaync-client -swb";
        on-click = "${swaync}/bin/swaync-client -t -sw";
        on-click-right = "${swaync}/bin/swaync-client -d -sw";
        escape = true;
      };
    };

    wayland.windowManager.sway.config.keybindings."Ctrl+Mod1+N" =
      "exec ${swaync}/bin/swaync-client -t -sw";

    systemd.user.services.gaia-desktop-event-notifier = {
      Unit = {
        Description = "Notify about meaningful Gaia desktop state changes";
        After = [ "swaync.service" ];
        Wants = [ "swaync.service" ];
        PartOf = [ config.wayland.systemd.target ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = gaiaDesktopEventNotifier;
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ config.wayland.systemd.target ];
    };
  };
}
