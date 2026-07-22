{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome;

  mkSearchEngine = name: template: alias: {
    inherit name;
    urls = [ { inherit template; } ];
    definedAliases = [ alias ];
  };
in
{
  config = lib.mkIf cfg.profiles.enableDesktop {
    stylix.targets.zen-browser.profileNames = [ "default" ];

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = false;

      nativeMessagingHosts = [ pkgs.tridactyl-native ];

      policies.ExtensionSettings = {
        "tridactyl.vim@cmcaine.co.uk" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi";
        };
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };

      profiles.default.search = {
        force = true;
        engines = {
          google-shortcut = mkSearchEngine "Google" "https://www.google.com/search?hl=en&q={searchTerms}" "g";
          wikipedia-shortcut =
            mkSearchEngine "Wikipedia"
              "https://en.wikipedia.org/wiki/Special:Search?search={searchTerms}&go=Go&ns0=1"
              "w";
          home-manager-options =
            mkSearchEngine "Home Manager Options"
              "https://home-manager-options.extranix.com/?query={searchTerms}&release=master"
              "hm";
          youtube-shortcut =
            mkSearchEngine "YouTube" "https://www.youtube.com/results?search_query={searchTerms}"
              "y";
          nix-packages =
            mkSearchEngine "Nix Packages"
              "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"
              "np";
          nix-options =
            mkSearchEngine "NixOS Options"
              "https://search.nixos.org/options?channel=unstable&query={searchTerms}"
              "no";
        };
      };
    };

    xdg.configFile."tridactyl/tridactylrc".text = ''
      " Search aliases migrated from qutebrowser.
      set searchurls.g https://www.google.com/search?hl=en&q=%s
      set searchurls.w https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go&ns0=1
      set searchurls.hm https://home-manager-options.extranix.com/?query=%s&release=master
      set searchurls.y https://www.youtube.com/results?search_query=%s
      set searchurls.np https://search.nixos.org/packages?channel=unstable&query=%s
      set searchurls.no https://search.nixos.org/options?channel=unstable&query=%s
      set searchengine g

      " Keep the core qutebrowser-style normal-mode bindings explicit.
      bind j scrollline 10
      bind k scrollline -10
      bind gg scrollto 0
      bind G scrollto 100
      bind f hint
      bind F hint -b
      bind o fillcmdline open
      bind t fillcmdline tabopen
      bind d tabclose
      bind u undo
      bind H back
      bind L forward
      bind r reload
      bind yy clipboard yank
    '';
  };
}
