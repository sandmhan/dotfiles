{ lib, pkgs, ...}:
{
  home = {
    # Define user packages here
    packages = with pkgs; [
      hello
    ];

    # This needs to match the actual username logged into
    username = "sandmhan";
    homeDirectory = "/home/sandmhan";

    # Does not need to be changed
    # Don't change this after the first build.
    stateVersion = "24.11";
  };
}
