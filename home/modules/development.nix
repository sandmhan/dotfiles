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
  # Always import development modules, control with options
  imports = [
    ../../homeModules/claude.nix
  ];

  # Development packages
  home.packages =
    with pkgs;
    # Development tools
    lib.optionals cfg.profiles.enableDevelopment [
      typst
      git
    ]
    # Container tools
    ++ lib.optionals cfg.features.enableContainerTools [
      docker-compose
      podman-compose
    ]
    # Virtualization tools (Linux only)
    ++ lib.optionals (cfg.profiles.enableVirtualization && cfg.platform.enableLinuxSpecific) [
      qemu
      libvirt
    ];

  # Development environment variables
  home.sessionVariables = lib.mkIf cfg.profiles.enableDevelopment {
    EDITOR = "nvim";
    BROWSER = if cfg.platform.enableLinuxSpecific then "firefox" else "open";
  };
}
