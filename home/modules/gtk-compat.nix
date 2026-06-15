{ config, lib, ... }:
{
  # Preserve Home Manager's legacy GTK4 theme behavior at default priority so
  # theme providers such as Stylix can override GTK4 theming without conflicts.
  gtk.gtk4.theme = lib.mkDefault config.gtk.theme;
}
