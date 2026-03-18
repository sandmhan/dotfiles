{
  pkgs,
  lib,
  ...
}:
{
  home = {
    packages = with pkgs; [
      orca-slicer
      freecad
      openscad
    ];
  };
}
