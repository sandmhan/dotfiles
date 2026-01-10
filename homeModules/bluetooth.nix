{
  pkgs,
  lib,
  ...
}:
{

  home = {
    packages = with pkgs; [
      bluetui
    ];
  };

}
