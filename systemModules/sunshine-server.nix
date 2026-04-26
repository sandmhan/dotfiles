# Sunshine Remote Gaming Server Module
# Provides headless game streaming via Sunshine with GPU passthrough,
# virtual display, PipeWire audio, and Moonlight client support
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.sunshine;
in
{
  options.homelab.sunshine = {
    enable = mkEnableOption "Homelab Sunshine remote gaming server";

    deploymentType = mkOption {
      type = types.enum [
        "vm"
        "container"
        "hybrid"
      ];
      default = "vm";
      description = "Deployment type - affects resource allocation and feature set";
    };

    resourceProfile = mkOption {
      type = types.enum [
        "minimal"
        "standard"
        "high"
      ];
      default = "high";
      description = "Resource profile for automatic configuration optimization";
    };

    # GPU configuration for passthrough
    gpu = {
      pciId = mkOption {
        type = types.str;
        default = "0000:01:00.0";
        description = "PCI bus ID for the GPU (PLACEHOLDER - update after passthrough setup)";
      };

      driver = mkOption {
        type = types.enum [
          "nvidia"
          "amd"
        ];
        default = "nvidia";
        description = "GPU driver type";
      };

      model = mkOption {
        type = types.str;
        default = "RTX 3060";
        description = "Descriptive GPU model name (for documentation)";
      };
    };

    # Virtual display configuration
    display = {
      resolution = mkOption {
        type = types.str;
        default = "1920x1080";
        description = "Virtual display resolution";
      };

      refreshRate = mkOption {
        type = types.int;
        default = 60;
        description = "Virtual display refresh rate in Hz";
      };
    };

    # Audio configuration
    audio = {
      backend = mkOption {
        type = types.enum [
          "pipewire"
          "pulseaudio"
        ];
        default = "pipewire";
        description = "Audio backend for game streaming audio capture";
      };
    };

    # Network configuration
    network = {
      controlPort = mkOption {
        type = types.port;
        default = 47989;
        description = "Sunshine web UI / control port";
      };

      videoPort = mkOption {
        type = types.port;
        default = 47984;
        description = "Sunshine video streaming port";
      };

      upnp = mkOption {
        type = types.bool;
        default = false;
        description = "Enable UPnP for automatic port forwarding (not recommended for homelab)";
      };
    };
  };

  config = mkMerge [
    # NVIDIA GPU driver and graphics setup
    (mkIf (cfg.enable && cfg.gpu.driver == "nvidia") {
      # NVIDIA proprietary drivers for GPU passthrough
      hardware.nvidia = {
        modesetting.enable = true;
        open = false; # Use proprietary drivers for game streaming
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        nvidiaSettings = true;
      };

      hardware.graphics = {
        enable = true;
        enable32Bit = true; # 32-bit support for games
      };

      # Load nvidia driver for Xorg
      services.xserver.videoDrivers = [ "nvidia" ];

      # NVIDIA kernel modules
      boot.initrd.kernelModules = [ "nvidia" ];
      boot.extraModulePackages = [ config.boot.kernelPackages.nvidiaPackages.stable ];
    })

    # AMD GPU setup (placeholder for 1080 Ti alternative)
    (mkIf (cfg.enable && cfg.gpu.driver == "amd") {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      services.xserver.videoDrivers = [ "amdgpu" ];

      boot.initrd.kernelModules = [
        "amdgpu"
      ];
    })

    # Virtual display via Xorg with dummy driver for headless operation
    (mkIf cfg.enable {
      services.xserver = {
        enable = true;

        # Minimal display manager for headless startup
        displayManager.startx.enable = true;

        # Xorg configuration for virtual display
        # PLACEHOLDER: Fine-tune modeline for specific resolution/refresh
        extraConfig = ''
          Section "Monitor"
            Identifier "VirtualMonitor"
            # PLACEHOLDER: Adjust modeline for ${cfg.display.resolution}@${toString cfg.display.refreshRate}Hz
            Option "PreferredMode" "${cfg.display.resolution}"
          EndSection

          Section "Screen"
            Identifier "VirtualScreen"
            Monitor "VirtualMonitor"
            DefaultDepth 24
            SubSection "Display"
              Depth 24
              Modes "${cfg.display.resolution}"
            EndSubSection
          EndSection
        '';
      };
    })

    # PipeWire audio backend
    (mkIf (cfg.enable && cfg.audio.backend == "pipewire") {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true; # PulseAudio compatibility layer
      };

      # PipeWire needs rtkit for real-time scheduling
      security.rtkit.enable = true;
    })

    # PulseAudio backend (alternative)
    (mkIf (cfg.enable && cfg.audio.backend == "pulseaudio") {
      services.pulseaudio = {
        enable = true;
        support32Bit = true;
        systemWide = true; # System-wide for headless operation
      };
    })

    # Sunshine game streaming service
    (mkIf cfg.enable {
      # Allow unfree packages (NVIDIA drivers, potentially Steam)
      nixpkgs.config.allowUnfree = true;

      # Sunshine system service (headless, no user session required)
      systemd.services.sunshine = {
        description = "Sunshine Game Streaming Server";
        wantedBy = [ "multi-user.target" ];
        after = [
          "display-manager.service"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.sunshine}/bin/sunshine";
          Restart = "on-failure";
          RestartSec = "10s";

          # Sunshine needs access to GPU, display, and input devices
          Environment = [
            "DISPLAY=:0"
            "XDG_RUNTIME_DIR=/run/user/0"
            # PLACEHOLDER: May need additional env vars for NVIDIA
            # "LD_LIBRARY_PATH=/run/opengl-driver/lib"
          ];

          # Security hardening while allowing necessary access
          SupplementaryGroups = [
            "video"
            "render"
            "input"
          ];

          # Resource limits based on profile
          MemoryMax =
            if cfg.resourceProfile == "high" then
              "8G"
            else if cfg.resourceProfile == "standard" then
              "4G"
            else
              "2G";
        };
      };

      # Sunshine configuration file
      environment.etc."sunshine/sunshine.conf".text = ''
        # Sunshine Game Streaming Configuration
        # Web UI accessible at https://<host>:${toString cfg.network.controlPort}

        # Network settings
        address_family = both
        channels = 5
        port = ${toString cfg.network.videoPort}
        upnp = ${if cfg.network.upnp then "on" else "off"}

        # Video settings — optimized for ${cfg.gpu.model}
        sw_preset = superfast
        adapter_name =
        output_name =
        # PLACEHOLDER: Tune encoder settings for ${cfg.gpu.model}
        # encoder = nvenc  # For NVIDIA GPUs
        # nvenc_preset = p4  # Balance quality/latency

        # Audio settings
        audio_sink = auto

        # Input settings
        gamepad = auto
        key_rightalt_to_key_win = enabled

        # Security settings
        # PLACEHOLDER: Configure credentials via SOPS
        # credentials_file = /run/secrets/sunshine-credentials

        # Logging
        min_log_level = info
        log_colorized = true

        # Display settings
        # PLACEHOLDER: Auto-configure from display options
        # resolution = ${cfg.display.resolution}
        # fps = ${toString cfg.display.refreshRate}
      '';

      # SOPS secrets for Sunshine credentials
      sops.secrets = {
        "sunshine-username" = {
          mode = "0600";
        };
        "sunshine-password" = {
          mode = "0600";
        };
      };

      # Packages from centralized registry plus gaming-specific
      environment.systemPackages =
        servicePackages.base
        ++ [
          pkgs.sunshine
          pkgs.xorg.xrandr # Display management
          pkgs.xorg.xdpyinfo # Display info
          pkgs.vulkan-tools # Vulkan diagnostics
          pkgs.mesa-demos # OpenGL diagnostics (glxinfo, etc.)
          pkgs.pciutils # lspci for GPU verification
        ]
        ++ optionals (cfg.gpu.driver == "nvidia") [
          pkgs.nvtopPackages.nvidia # NVIDIA GPU monitoring
        ];
    })

    # Node exporter for Prometheus monitoring
    (mkIf cfg.enable {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "systemd"
          "processes"
        ]
        ++ optionals (cfg.deploymentType == "vm") [
          "interrupts"
          "logind"
        ];
      };
    })

    # Firewall configuration
    (mkIf cfg.enable {
      networking.firewall = {
        # Sunshine control and web UI
        allowedTCPPorts = [
          22 # SSH
          cfg.network.controlPort # Sunshine web UI (47989)
          (cfg.network.controlPort + 1) # HTTPS web UI (47990)
          cfg.network.videoPort # Video stream (47984)
          9100 # Node exporter
        ];

        # Sunshine/Moonlight UDP ports for streaming
        allowedUDPPorts = [
          cfg.network.videoPort # Video (47984)
          (cfg.network.videoPort + 14) # Audio and control (47998)
          (cfg.network.videoPort + 15) # 47999
          (cfg.network.videoPort + 16) # 48000
          (cfg.network.videoPort + 17) # 48001
          (cfg.network.videoPort + 18) # 48002
          (cfg.network.videoPort + 19) # 48003
          (cfg.network.videoPort + 20) # 48004
          (cfg.network.videoPort + 21) # 48005
          (cfg.network.videoPort + 22) # 48006
          (cfg.network.videoPort + 23) # 48007
          (cfg.network.videoPort + 24) # 48008
          (cfg.network.videoPort + 25) # 48009
          (cfg.network.videoPort + 26) # 48010
        ];
      };
    })

    # Kernel tuning for gaming workloads
    (mkIf cfg.enable {
      boot.kernel.sysctl = {
        # Increase shared memory for GPU and gaming workloads
        "kernel.shmmax" = 8589934592; # 8GB
        "kernel.shmall" = 4194304;

        # Network tuning for low-latency streaming
        "net.core.rmem_max" = 26214400;
        "net.core.wmem_max" = 26214400;
        "net.core.rmem_default" = 1048576;
        "net.core.wmem_default" = 1048576;
        "net.core.netdev_max_backlog" = 5000;

        # Reduce swappiness for gaming performance
        "vm.swappiness" = 10;

        # Increase inotify limits
        "fs.inotify.max_user_watches" = 524288;
        "fs.inotify.max_user_instances" = 256;
      };
    })

    # Systemd resource limits based on deployment type
    (mkIf (cfg.enable && cfg.deploymentType == "container") {
      systemd.services.sunshine.serviceConfig = {
        MemoryMax = "2G";
        CPUQuota = "200%"; # 2 cores
      };
    })

    (mkIf (cfg.enable && cfg.deploymentType != "container" && cfg.resourceProfile == "minimal") {
      systemd.services.sunshine.serviceConfig = {
        MemoryMax = "4G";
        CPUQuota = "400%"; # 4 cores
      };
    })

    # Health check service
    (mkIf cfg.enable {
      systemd.services.sunshine-health-check = {
        description = "Sunshine Game Streaming Health Check";
        wantedBy = [ "multi-user.target" ];
        after = [ "sunshine.service" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "sunshine-health-check" ''
            sleep 15

            echo "Checking Sunshine game streaming services..."

            # Check Sunshine web UI
            if ${pkgs.curl}/bin/curl -sf -k https://localhost:${toString (cfg.network.controlPort + 1)}/api/apps >/dev/null 2>&1; then
              echo "Sunshine web UI is responding"
            else
              echo "Warning: Sunshine web UI not responding (may need initial pairing)"
            fi

            # Check GPU availability
            if ${pkgs.pciutils}/bin/lspci | grep -qi "vga\|3d\|display"; then
              echo "GPU detected"
              ${optionalString (cfg.gpu.driver == "nvidia") ''
                if command -v nvidia-smi >/dev/null 2>&1; then
                  echo "NVIDIA driver loaded:"
                  nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo "  nvidia-smi query failed"
                else
                  echo "Warning: nvidia-smi not found"
                fi
              ''}
            else
              echo "Warning: No GPU detected (check passthrough configuration)"
            fi

            # Check display
            if [ -n "''${DISPLAY:-}" ] || [ -e /tmp/.X11-unix/X0 ]; then
              echo "X display available"
            else
              echo "Warning: No X display detected"
            fi

            # Check audio
            ${optionalString (cfg.audio.backend == "pipewire") ''
              if systemctl is-active pipewire.service >/dev/null 2>&1; then
                echo "PipeWire audio service running"
              else
                echo "Warning: PipeWire not running"
              fi
            ''}

            echo "Health check complete"
          '';
        };

        startAt = "hourly";
      };
    })
  ];
}
