{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.myHome;
in
{
  imports = [
    ./ai-skills.nix
    ./ai-claude.nix
    ./ai-codex.nix
    ./ai-pi.nix
  ];

  # Development packages
  home.packages =
    with pkgs;
    lib.optionals cfg.profiles.enableDevelopment [
      typst
      git
      sops
      age
      ssh-to-age
    ]
    ++ lib.optionals cfg.features.enableContainerTools [
      docker-compose
      podman-compose
    ]
    ++ lib.optionals (cfg.profiles.enableVirtualization && cfg.platform.enableLinuxSpecific) [
      qemu
      libvirt
    ];

  # Development shell environments
  programs.direnv = lib.mkIf cfg.profiles.enableDevelopment {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  # Development environment variables
  home.sessionVariables = lib.mkIf cfg.profiles.enableDevelopment {
    EDITOR = "nvim";
    BROWSER = if cfg.platform.enableLinuxSpecific then "firefox" else "open";
  };
}
