{ lib, pkgs, userSettings, ...}:
let
  username = userSettings.username;
in
{
  home = {
    # Define user packages here
    packages = with pkgs; [
      git
      hello
    ];

    # This needs to match the actual username logged into
    inherit username;
    homeDirectory = "/home/${username}";

    # Does not need to be changed
    # Don't change this after the first build.
    stateVersion = "24.11";
  };
}
