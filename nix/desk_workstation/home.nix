{ lib, pkgs, userSettings, ...}:
let
  username = userSettings.username;
in
{
  home = {
    # Define user packages here
    packages = with pkgs; [
      hello
    ];

    # This needs to match the actual username logged into
    inherit username;
    homeDirectory = "/home/${username}";

    file."stuff.txt".text = "stuff \n stuff";

    # Does not need to be changed
    # Don't change this after the first build.
    stateVersion = "24.11";
  };
}
