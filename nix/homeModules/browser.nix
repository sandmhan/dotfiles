{
  ...
}:
{

  programs.qutebrowser = {
    enable = true;

    searchEngines = {
      w = "https://en.wikipedia.org/wiki/Special:Search?search={}&amp;go=Go&amp;ns0=1";
      g = "https://www.google.com/search?hl=en&amp;q={}";
      hm = "https://home-manager-options.extranix.com/?query={}&release=master";
      y = "https://www.youtube.com/results?search_query={}";
      np = "https://search.nixos.org/packages?channel=unstable&query={}";
      no = "https://search.nixos.org/options?channel=unstable&query={}";
    };

    settings = {
      tabs = {
        position = "left";
        max_width = 1;
        show = "switching";
      };
      scrolling.smooth = true;

      colors.webpage.darkmode.enabled = true;

      # Remove the finished downloads after 5 second
      downloads.remove_finished = 5000;
    };
    extraConfig = ''
      c.content.javascript.log_message.excludes = {
        'userscript:_qute_stylesheet' : ['*Refused to apply inline style because it violates the following Content Security Policy directive: *'],
        'userscript:_qute_js' : ['*TrustedHTML*']
      }
    '';
  };

}
