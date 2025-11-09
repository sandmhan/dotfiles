{
  pkgs,
  ...
}:
{
  stylix = {
    enable = true;

    # Current theme file
    # TODO: Make this sourced from personal colorscheme and linked wallpaper like librephoenix's config
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    fonts = {
      # Monospace font for terminals and code editors
      monospace = {
        package = pkgs.nerd-fonts.blex-mono;
        name = "BlexMono Nerd Font";
      };

      # Optional: emoji font, if you want emojis to render properly
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };

  fonts.fontconfig.enable = true;
}
