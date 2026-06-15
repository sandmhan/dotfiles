{ config, lib, ... }:
{
  # Preserve Home Manager's legacy GTK4 theme behavior explicitly for profiles
  # with stateVersion < 26.05 so evaluation stays warning-free.
  gtk.gtk4.theme = lib.mkDefault config.gtk.theme;
}
