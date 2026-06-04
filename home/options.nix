{
  lib,
  config,
  ...
}:
let
  cfg = config.myHome;
in
{
  options.myHome = with lib; {
    profiles = {
      enableDesktop = mkEnableOption "desktop environment with GUI applications";
      enableDevelopment = mkEnableOption "development tools and IDE configurations";
      enableGaming = mkEnableOption "gaming packages and configurations";
      enableMedia = mkEnableOption "media applications (mpv, image viewers, etc.)";
      enableOffice = mkEnableOption "office suite and productivity apps";
      enableSocial = mkEnableOption "social applications (Discord, Matrix, etc.)";
      enableVirtualization = mkEnableOption "virtualization tools (Docker, QEMU, etc.)";
    };

    features = {
      # Terminal features
      enableAdvancedShell = mkEnableOption "advanced shell features (starship, zoxide, etc.)";
      enableGitExtensions = mkEnableOption "extended git tools (gitui, gh, etc.)";
      enableTerminalUtils = mkEnableOption "advanced terminal utilities (ripgrep, fd, bat, etc.)";

      # Desktop features
      enableWindowManager = mkEnableOption "window manager (Sway/Hyprland)";
      enableDisplayManager = mkEnableOption "display manager and login screen";
      enableAudioTools = mkEnableOption "audio management tools";
      enableBluetoothTools = mkEnableOption "Bluetooth management";
      enableNetworkTools = mkEnableOption "network management GUI tools";
      enableScreenshotTools = mkEnableOption "screenshot and screen recording tools (grim, slurp, swappy, wf-recorder)";
      enable3DPrinting = mkEnableOption "3D printing tools (FreeCAD, OrcaSlicer, OpenSCAD)";

      # AI tools
      enableAISkills = mkEnableOption "shared AI skills and rules content";
      enableClaudeCode = mkEnableOption "Claude Code configuration";
      enableCodex = mkEnableOption "OpenAI Codex CLI configuration";
      enablePi = mkEnableOption "pi coding agent configuration";
      enableNvfAiCodeCompanion = mkEnableOption "CodeCompanion.nvim Codex ACP assistant workflow for NVF";

      # Development features
      enableNixvim = mkEnableOption "Nixvim/Neovim configuration";
      enableContainerTools = mkEnableOption "container development tools";

      # Remote desktop features
      enableMoonlight = mkEnableOption "Moonlight game streaming client";
      enableSunshine = mkEnableOption "Sunshine game streaming server";

      # System features
      enableFonts = mkEnableOption "custom fonts and typography";
      enableTheming = mkEnableOption "Stylix theming system";
      enableSecurity = mkEnableOption "security tools (Bitwarden, VPN, etc.)";

      # Theme selection
      theme = mkOption {
        type = lib.types.str;
        default = "gruvbox-dark-hard";
        description = "Active base16 color scheme name (must match a directory in themes/)";
      };
    };

    platform = {
      # Platform-specific options
      enableLinuxSpecific = mkOption {
        type = lib.types.bool;
        default = true; # Will be set properly in configs
        description = "Enable Linux-specific packages and configurations";
      };

      enableDarwinSpecific = mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable macOS-specific packages and configurations";
      };

      isHeadless = mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this is a headless system (no GUI)";
      };

      isWSL = mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this is running under WSL";
      };
    };

    user = {
      enableKeyboardCustomization = mkEnableOption "custom keyboard layouts and options";
      enableDotfileSymlinks = mkEnableOption "symlink dotfiles to home directory";
    };
  };

  # Auto-derive shared AI skill content and pi integration when any AI tool is enabled
  config.myHome.features.enablePi = lib.mkDefault (
    cfg.features.enableClaudeCode || cfg.features.enableCodex
  );
  config.myHome.features.enableAISkills = lib.mkDefault (
    cfg.features.enableClaudeCode || cfg.features.enableCodex || cfg.features.enablePi
  );
}
