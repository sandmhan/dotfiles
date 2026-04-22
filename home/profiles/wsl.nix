{
  lib,
  ...
}:
{
  imports = [
    ./terminal.nix
  ];

  # WSL-specific profile configuration - override terminal defaults
  myHome = {
    platform = {
      isWSL = true; # Override terminal.nix default
    };

    features = {
      # Enhanced development environment for WSL
      enableContainerTools = true; # Override terminal.nix default - Docker is common in WSL
    };

    profiles = {
      # Override specific profiles for WSL environment
      enableVirtualization = false; # Avoid nested virtualization issues
    };
  };
}
