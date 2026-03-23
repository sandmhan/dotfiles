{
  pkgs,
  lib,
  ...
}:
{
  home = {
    packages = with pkgs; [
      orca-slicer
      qidi-studio
      freecad
      openscad
    ];
  };
}
