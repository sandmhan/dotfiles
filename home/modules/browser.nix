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

    xdg = {
      mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/bitwarden" = "bitwarden.desktop";
          "x-scheme-handler/discord" = "legcord.desktop";
          "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
        };
      };

      configFile."mimeapps.list".force = true;
      dataFile."applications/mimeapps.list".force = true;
    };

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;

      nativeMessagingHosts = [ pkgs.tridactyl-native ];

      policies.PasswordManagerEnabled = false;

      policies.Preferences."sidebar.visibility" = {
        Value = "expand-on-hover";
        Status = "locked";
      };

      policies.ExtensionSettings = {
        "tridactyl.vim@cmcaine.co.uk" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi";
          private_browsing = true;
        };
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          private_browsing = true;
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        };
      };

      profiles.default.settings = {
        "browser.sessionstore.restore_tabs_lazily" = false;
        "zen.urlbar.replace-newtab" = false;
      };

      profiles.default.userChrome = lib.mkAfter ''
        .webextension-browser-action
          > .toolbarbutton-badge-stack
          > .toolbarbutton-badge {
          display: none !important;
        }
      '';

      profiles.default.search = {
        force = true;
        default = "ddg";
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
      set searchurls.ddg https://duckduckgo.com/?q=%s
      set searchengine ddg

      " Keep the core qutebrowser-style normal-mode bindings explicit.
      bind j scrollline 10
      bind k scrollline -10
      bind J tabnext
      bind K tabprev
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
