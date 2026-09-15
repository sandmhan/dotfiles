# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  systemSettings,
  remoteCommunity,
  ...
}:
let
  gaiaScreenShareChooser = pkgs.writeShellScript "gaia-screen-share-chooser" ''
    set -eu

    runtime_base="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    runtime_dir="$runtime_base/xdpw-chooser"
    marker_file="$runtime_base/legcord-screencast-request"
    options_file="$(${pkgs.coreutils}/bin/mktemp "''${TMPDIR:-/tmp}/xdpw-options.XXXXXX")"
    cache_file="$runtime_dir/cache"
    cache_tmp="$runtime_dir/cache.$$"
    completed_file="$runtime_dir/completed"
    completed_tmp="$runtime_dir/completed.$$"
    trap '${pkgs.coreutils}/bin/rm -f "$options_file" "$cache_tmp" "$completed_tmp"' EXIT

    read_legcord_request() {
      request_pid=""
      request_token=""
      request_deadline=""
      [ -f "$marker_file" ] || return 1
      {
        IFS= read -r request_pid || true
        IFS= read -r request_token || true
        IFS= read -r request_deadline || true
      } < "$marker_file"
      case "$request_pid:$request_deadline" in
        *[!0-9:]* | :* | *:) return 1 ;;
      esac
      [ -n "$request_token" ] || return 1
      [ "$(${pkgs.coreutils}/bin/date +%s)" -le "$request_deadline" ] || return 1
      [ -r "/proc/$request_pid/cmdline" ] || return 1
      ${pkgs.gnugrep}/bin/grep --null-data --fixed-strings --quiet \
        -- '/share/lib/legcord/resources/app.asar' "/proc/$request_pid/cmdline"
    }

    ${pkgs.coreutils}/bin/cat > "$options_file"
    ${pkgs.coreutils}/bin/mkdir -p -m 700 "$runtime_dir"
    umask 077
    exec 9>"$runtime_dir/lock"
    ${pkgs.util-linux}/bin/flock 9

    active_token=""
    if read_legcord_request; then
      active_token="$request_token"
    fi
    completed_token=""
    if [ -f "$completed_file" ]; then
      IFS= read -r completed_token < "$completed_file" || true
    fi
    if [ "$completed_token" = "$active_token" ]; then
      active_token=""
    fi

    cached_token=""
    deadline=""
    remaining=""
    selected=""
    if [ -f "$cache_file" ]; then
      {
        IFS= read -r cached_token || true
        IFS= read -r deadline || true
        IFS= read -r remaining || true
        IFS= read -r selected || true
      } < "$cache_file"
    fi

    now="$(${pkgs.coreutils}/bin/date +%s)"
    case "$deadline:$remaining" in
      *[!0-9:]* | :* | *:)
        ;;
      *)
        if [ -n "$active_token" ] \
          && [ "$cached_token" = "$active_token" ] \
          && [ "$now" -le "$deadline" ] \
          && [ "$remaining" -gt 0 ] \
          && ${pkgs.gnugrep}/bin/grep -Fqx -- "$selected" "$options_file"; then
          remaining=$((remaining - 1))
          if [ "$remaining" -gt 0 ]; then
            printf '%s\n%s\n%s\n%s\n' \
              "$cached_token" "$deadline" "$remaining" "$selected" > "$cache_tmp"
            ${pkgs.coreutils}/bin/mv -f "$cache_tmp" "$cache_file"
          else
            ${pkgs.coreutils}/bin/rm -f "$cache_file"
            printf '%s\n' "$active_token" > "$completed_tmp"
            ${pkgs.coreutils}/bin/mv -f "$completed_tmp" "$completed_file"
          fi
          ${pkgs.coreutils}/bin/sleep 0.5
          printf '%s\n' "$selected"
          exit 0
        fi
        ;;
    esac

    ${pkgs.coreutils}/bin/rm -f "$cache_file"
    selected="$(${lib.getExe pkgs.rofi} -dmenu -i -p 'Share screen' < "$options_file")" || exit $?
    [ -n "$selected" ] || exit 1

    if [ -n "$active_token" ] \
      && read_legcord_request \
      && [ "$request_token" = "$active_token" ]; then
      deadline=$(( $(${pkgs.coreutils}/bin/date +%s) + 8 ))
      printf '%s\n%s\n2\n%s\n' "$active_token" "$deadline" "$selected" > "$cache_tmp"
      ${pkgs.coreutils}/bin/mv -f "$cache_tmp" "$cache_file"
    fi
    printf '%s\n' "$selected"
  '';

  gaiaRemoteCommunityActuator = remoteCommunity.packages.x86_64-linux.android-gate-actuator;
  gaiaRemoteCommunityDispatcher = pkgs.writeShellScript "gaia-remote-community-dispatcher" ''
    set -eu

    case "''${SSH_ORIGINAL_COMMAND-}" in
      back_gate)
        label='Back Gate Controller'
        ;;
      main_entrance)
        label='Main Entrance'
        ;;
      *)
        exit 2
        ;;
    esac

    uid="$(${pkgs.coreutils}/bin/id -u)"
    exec ${pkgs.coreutils}/bin/env -i \
      HOME=/home/sandmhan \
      USER=sandmhan \
      LOGNAME=sandmhan \
      XDG_RUNTIME_DIR="/run/user/$uid" \
      ${pkgs.coreutils}/bin/timeout --kill-after=5s 75s \
      ${gaiaRemoteCommunityActuator}/bin/android-gate-actuator "$label"
  '';

  gaiaFanCommon = ''
    set -eu

    script=$(basename "$0")

    find_ec_tool() {
      if command -v ectool >/dev/null 2>&1; then
        command -v ectool
      elif command -v fw-ectool >/dev/null 2>&1; then
        command -v fw-ectool
      else
        echo "error: neither ectool nor fw-ectool is available in PATH" >&2
        echo "Gaia fan scripts require one of these EC tools." >&2
        exit 127
      fi
    }

    require_root() {
      if [ "$(id -u)" -ne 0 ]; then
        echo "error: EC fan access requires root privileges." >&2
        echo "Run this with sudo/root, e.g. sudo $script ..." >&2
        exit 1
      fi
    }

    tool=$(find_ec_tool)
    require_root
  '';

  # Gaia fan control is intentionally manual only: no daemon is installed and
  # no passwordless sudo/polkit broadening is added. Previous local preflight
  # confirmed ectool appears to expose the needed commands, but behavior could
  # not be verified without interactive sudo/root access.
  gaiaFanStatus = pkgs.writeShellScriptBin "gaia-fan-status" ''
    ${gaiaFanCommon}

    echo "Gaia fan status (read-only via $tool)"
    echo
    echo "Number of fans:"
    "$tool" pwmgetnumfans
    echo
    echo "Fan RPM:"
    "$tool" pwmgetfanrpm all
    echo
    echo "Fan duty:"
    "$tool" pwmgetduty
  '';

  gaiaFanAuto = pkgs.writeShellScriptBin "gaia-fan-auto" ''
    ${gaiaFanCommon}

    # Framework/ChromeOS ectool expects autofanctrl with no fan index or
    # boolean argument. Passing "on" is parsed as a fan index on Gaia and
    # returns "Bad fan index.".
    "$tool" autofanctrl
    echo "Automatic EC fan control has been restored."
  '';

  gaiaFanDuty = pkgs.writeShellScriptBin "gaia-fan-duty" ''
    ${gaiaFanCommon}

    usage() {
      echo "Usage: sudo gaia-fan-duty <30-100>" >&2
      echo "Restore automatic control with: sudo gaia-fan-auto" >&2
    }

    if [ "$#" -ne 1 ]; then
      usage
      exit 2
    fi

    percent="$1"
    case "$percent" in
      ""|*[!0-9]*)
        usage
        exit 2
        ;;
    esac

    if [ "$percent" -lt 30 ] || [ "$percent" -gt 100 ]; then
      usage
      exit 2
    fi

    echo "Setting manual fan duty to $percent%."
    echo "Warning: manual fan duty persists until automatic control is restored."
    "$tool" fanduty "$percent"
    echo "Restore automatic control with: sudo gaia-fan-auto"
  '';

  gaiaPowerSourcePolicy = pkgs.writeShellScript "gaia-power-source-policy" ''
    set -eu

    ac_online=/sys/class/power_supply/ACAD/online
    lid_state=/proc/acpi/button/lid/LID0/state

    if [ ! -r "$ac_online" ]; then
      exit 0
    fi

    case "$(<"$ac_online")" in
      1)
        if ! ${pkgs.coreutils}/bin/timeout 5s \
          ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced; then
          ${pkgs.util-linux}/bin/logger -t gaia-power \
            "Unable to select the balanced power profile on AC"
        fi
        ;;
      0)
        if ! ${pkgs.coreutils}/bin/timeout 5s \
          ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver; then
          ${pkgs.util-linux}/bin/logger -t gaia-power \
            "Unable to select the power-saver profile on battery"
        fi

        # The udev event can race with sysfs updates. Only request sleep after
        # both sources confirm that external power is gone and the lid remains
        # closed. Profile selection failure must not bypass this safety path.
        if [ -r "$lid_state" ] && ${pkgs.gnugrep}/bin/grep -q 'closed' "$lid_state"; then
          ${pkgs.util-linux}/bin/logger -t gaia-power \
            "AC disconnected with lid closed; requesting suspend-then-hibernate"
          ${pkgs.systemd}/bin/systemctl --no-block suspend-then-hibernate
        fi
        ;;
    esac
  '';

  gaiaApplyBatteryChargeLimit = pkgs.writeShellScript "gaia-apply-battery-charge-limit" ''
    set -eu

    charge_limit=/sys/class/power_supply/BAT1/charge_control_end_threshold
    if [ ! -w "$charge_limit" ]; then
      ${pkgs.util-linux}/bin/logger -t gaia-power \
        "Battery charge-limit control is unavailable; retaining firmware policy"
      exit 0
    fi

    echo 80 > "$charge_limit"
  '';

  gaiaFirmwareStatus = pkgs.writeShellScriptBin "gaia-firmware-status" ''
    set -u

    echo "BIOS version: $(< /sys/class/dmi/id/bios_version)"
    echo
    ${pkgs.fwupd}/bin/fwupdmgr get-devices --no-unreported-check
    ${pkgs.fwupd}/bin/fwupdmgr get-history --no-unreported-check

    update_status=0
    ${pkgs.fwupd}/bin/fwupdmgr get-updates --no-unreported-check || update_status=$?
    if [ "$update_status" -ne 0 ] && [ "$update_status" -ne 2 ]; then
      exit "$update_status"
    fi
  '';
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../systemModules/google-glass.nix
    ../../systemModules/kinect-v2.nix
    ../../systemModules/sops.nix
    ../../systemModules/tailscale.nix
    #../../systemModules/jellyfin.nix
    # ../../systemModules/frigate.nix
  ];

  hardware.meridianKinect.enable = true;

  stylix = {
    enable = true;
    # System-level theme stays at a neutral default; HM-level Stylix
    # handles the active user theme via theme-switch. This avoids
    # needing nixos-rebuild for theme changes.
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 2;
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback.out
  ];

  boot.kernelModules = [
    "v4l2loopback"
  ];

  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=2 card_label="RTSP_Camera" exclusive_caps=1
    # Avoid MediaTek MT7925 Bluetooth firmware corruption across hibernation.
    options btusb enable_autosuspend=0
  '';

  # Enable Amd microcode updates
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Follow nixpkgs' maintained default kernel instead of jumping to every new
  # mainline release. The default remains new enough for the Ryzen AI platform.
  boot.kernelPackages = pkgs.linuxPackages;

  # Enable BIOS updates
  services.fwupd.enable = true;

  # xdg-document-portal mounts its per-user document store through FUSE.
  # Enable the privileged fusermount3 wrapper required for that mount.
  programs.fuse.enable = true;

  # Use one AMD-aware power manager. The Framework profile defaults to PPD;
  # explicit settings prevent the generic laptop profile from enabling TLP.
  services.power-profiles-daemon.enable = true;
  services.auto-cpufreq.enable = false;
  services.tlp.enable = false;

  # Enable graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Keep long-running work active when the lid is closed on AC. If AC is
  # removed while the lid remains closed, the udev-triggered safety service
  # below starts suspend-then-hibernate instead of leaving Gaia awake in a bag.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30min";
    HibernateOnACPower = false;
  };

  systemd.services.gaia-power-source-policy = {
    description = "Apply Gaia power policy when the power source changes";
    after = [
      "graphical.target"
      "power-profiles-daemon.service"
    ];
    wants = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = gaiaPowerSourcePolicy;
    };
  };

  # Defer the initial policy run until the graphical session and PPD are ready.
  # Power-source udev events continue to start the service directly.
  systemd.timers.gaia-power-source-policy = {
    description = "Apply Gaia power policy after graphical startup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "20s";
      Unit = "gaia-power-source-policy.service";
    };
  };

  systemd.services.gaia-battery-charge-limit = {
    description = "Keep Gaia battery charging capped at 80 percent";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = gaiaApplyBatteryChargeLimit;
    };
  };

  # Enable garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
    persistent = true; # Run on next boot if timer was missed
  };

  # Needed to setup Sway using Home Manager
  security.polkit.enable = true;

  # Keep the fingerprint reader available for enrollment and future display
  # manager/lock-screen evaluation. Ly uses a sequential PAM conversation, so
  # enabling fprintd there delays the password prompt until fingerprint timeout.
  services.fprintd.enable = true;

  # Configure PAM for fingerprint authentication
  security.pam.services = {

    sudo = {
      fprintAuth = false;
    };

    su = {
      fprintAuth = false;
    };

    login = {
      enable = true;
      fprintAuth = false;
      nodelay = true;
    };

    ly = {
      fprintAuth = false;
    };

    swaylock = {
      enable = false;
      fprintAuth = false;
      text = ''
        auth sufficient pam_unix.so try_first_pass likeauth nullok
        auth sufficient pam_fprintd.so
        auth include login
      '';
    };

    hyprland.fprintAuth = false;
  };

  networking.hostName = "gaia"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # KDE Connect uses Home Manager for the user service and package; the
  # NixOS module only owns the required TCP/UDP firewall ranges (1714-1764).
  programs.kdeconnect = {
    enable = true;
    package = null;
  };

  # Tailscale client; the dedicated VPN VM advertises homelab subnet routes.
  homelab.tailscale = {
    enable = true;
    acceptDNS = false; # Avoid stale MagicDNS forwarding after suspend or hibernate
    acceptRoutes = false; # Prefer Gaia's directly connected LAN over competing subnet routes
  };

  # Set your time zone.
  time.timeZone = systemSettings.timezone;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Optimise storage usage
  nix.settings.auto-optimise-store = true;

  nix.settings.download-buffer-size = 500000000; # 500 MB

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver = {
    enable = true;
  };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm = {
    enable = false;
    wayland.enable = false;
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      # See https://github.com/fairyglade/ly/blob/v1.0.2/res/config.ini for setting info
      pam = true;
      animation = "gameoflife";
      bigclock = "en";
      sleep_cmd = "systemctl sleep";
      vi-mode = true;
      initial_info_text = "~Konbanwatagwan, minnaslime~";
      hide_borders = true;
      hide_version_string = true;
      hide_key_hints = true;
      load = true;
      save = true;
    };
  };

  services.desktopManager.plasma6.enable = false;

  # Enabling hyprland
  programs.hyprland = {
    enable = false;
    xwayland.enable = true;
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # xdg-desktop-portal-wlr 0.8.3 can permanently stop producing frames when
  # Chromium/Electron temporarily holds every PipeWire buffer. Backport the
  # merged upstream recovery fix until it reaches the pinned nixpkgs revision.
  nixpkgs.overlays = [
    (_final: prev: {
      xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [ ./xdg-desktop-portal-wlr-buffer-starvation.patch ];
      });
    })
  ];

  # Electron opens three portal sessions for a normal Legcord window share.
  # Reuse the first choice for that request only. Discord's live Change Stream
  # flow opens overlapping requests and is intentionally unsupported here;
  # stop and restart the stream to choose another source.
  xdg.portal.wlr.settings.screencast = {
    chooser_type = "dmenu";
    chooser_cmd = "${gaiaScreenShareChooser}";
  };

  environment.sessionVariables = {
    #WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };

  # udev rules for QMK setup
  services.udev.extraRules = ''
    # Keep long-running sessions alive with the lid closed on AC, but suspend
    # safely if the charger is removed before the lid is reopened.
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="ACAD", TAG+="systemd", ENV{SYSTEMD_WANTS}+="gaia-power-source-policy.service"

    # Atmel DFU
    ### ATmega16U2
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2fef", TAG+="uaccess"
    ### ATmega32U2
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff0", TAG+="uaccess"
    ### ATmega16U4
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff3", TAG+="uaccess"
    ### ATmega32U4
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", TAG+="uaccess"
    ### AT90USB64
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff9", TAG+="uaccess"
    ### AT90USB162
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffa", TAG+="uaccess"
    ### AT90USB128
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", TAG+="uaccess"

    # Input Club
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1c11", ATTRS{idProduct}=="b007", TAG+="uaccess"

    # STM32duino
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1eaf", ATTRS{idProduct}=="0003", TAG+="uaccess"
    # STM32 DFU
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", TAG+="uaccess"

    # BootloadHID
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="05df", TAG+="uaccess"

    # USBAspLoader
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="05dc", TAG+="uaccess"

    # USBtinyISP
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1782", ATTRS{idProduct}=="0c9f", TAG+="uaccess"

    # ModemManager should ignore the following devices
    # Atmel SAM-BA (Massdrop)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="6124", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"

    # Caterina (Pro Micro)
    ## pid.codes shared PID
    ### Keyboardio Atreus 2 Bootloader
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2302", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ## Spark Fun Electronics
    ### Pro Micro 3V3/8MHz
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1b4f", ATTRS{idProduct}=="9203", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ### Pro Micro 5V/16MHz
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1b4f", ATTRS{idProduct}=="9205", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ### LilyPad 3V3/8MHz (and some Pro Micro clones)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1b4f", ATTRS{idProduct}=="9207", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ## Pololu Electronics
    ### A-Star 32U4
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1ffb", ATTRS{idProduct}=="0101", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ## Arduino SA
    ### Leonardo
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0036", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ### Micro
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0037", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ## Adafruit Industries LLC
    ### Feather 32U4
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="239a", ATTRS{idProduct}=="000c", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ### ItsyBitsy 32U4 3V3/8MHz
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="239a", ATTRS{idProduct}=="000d", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ### ItsyBitsy 32U4 5V/16MHz
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="239a", ATTRS{idProduct}=="000e", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ## dog hunter AG
    ### Leonardo
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="0036", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
    ### Micro
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="0037", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"

    # hid_listen
    KERNEL=="hidraw*", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"

    # hid bootloaders
    ## QMK HID
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2067", TAG+="uaccess"
    ## PJRC's HalfKay
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="0478", TAG+="uaccess"

    # APM32 DFU
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="314b", ATTRS{idProduct}=="0106", TAG+="uaccess"

    # GD32V DFU
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="28e9", ATTRS{idProduct}=="0189", TAG+="uaccess"

    # WB32 DFU
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="dfa0", TAG+="uaccess"

    # AT32 DFU
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e3c", ATTRS{idProduct}=="df11", TAG+="uaccess"
  '';

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "caps:escape";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    # rtkit covers baseline realtime scheduling for PipeWire/JACK. Further
    # realtime tuning (for example PAM limits or IRQ priorities) is deferred
    # until there is a measured need.

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Decrypt user password hash from sops
  sops.secrets.user-password = {
    neededForUsers = true;
  };

  # Define a user account.
  users.mutableUsers = false;
  # Passwordless sudo for tailscale toggle (waybar widget)
  security.sudo.extraRules = [
    {
      users = [ "sandmhan" ];
      commands = [
        {
          command = "${pkgs.tailscale}/bin/tailscale up";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.tailscale}/bin/tailscale down";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  users.users.sandmhan = {
    isNormalUser = true;
    description = "sandmhan";
    hashedPasswordFile = config.sops.secrets.user-password.path;
    openssh.authorizedKeys.keys = [
      ''restrict,from="100.122.240.66",command="${gaiaRemoteCommunityDispatcher}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFcYKszcC6Mmh6JFQXrEzPg2a53ahR3nPhocoN+CGtnG remote-community-vm111-forced-actuator''
    ];
    extraGroups = [
      "networkmanager"
      "video"
      "wheel"
    ];
    packages = with pkgs; [
      vim
      kdePackages.kate
      htop-vim
      pavucontrol
      #home-manager
      git
      gnumake
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enabling choice experimental features
  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    (with pkgs; [
      neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      lm_sensors
      framework-tool
      fw-ectool
      #  wget
    ])
    ++ [
      gaiaFanStatus
      gaiaFanAuto
      gaiaFanDuty
      gaiaFirmwareStatus
    ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
