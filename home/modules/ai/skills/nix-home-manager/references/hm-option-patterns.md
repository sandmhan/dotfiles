# Home Manager Option Patterns

## Shell Configuration

### programs.zsh

```nix
programs.zsh = {
  enable = true;
  dotDir = ".config/zsh";
  initContent = ''
    # Runs at end of .zshrc
    source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
  '';
  completionInit = "autoload -U compinit && compinit -C";
  shellAliases = {
    ll = "eza -la";
    gs = "git status";
  };
  oh-my-zsh = {
    enable = true;
    plugins = [ "git" "docker" ];
    theme = "robbyrussell";
  };
  # Alternative: zinit
  # zplug, prezto also available
};
```

### programs.bash

```nix
programs.bash = {
  enable = true;
  bashrcExtra = ''
    export EDITOR=nvim
  '';
  shellAliases = {
    ll = "eza -la";
  };
};
```

### programs.fish

```nix
programs.fish = {
  enable = true;
  interactiveShellInit = ''
    set fish_greeting ""
  '';
  shellAliases = {
    ll = "eza -la";
  };
};
```

### programs.starship

```nix
programs.starship = {
  enable = true;
  enableZshIntegration = true;
  settings = {
    add_newline = false;
    character.success_symbol = "[>](bold green)";
    nix_shell.format = "via [$symbol$state]($style) ";
  };
};
```

## Development Tools

### programs.git

```nix
programs.git = {
  enable = true;
  userName = "Your Name";
  userEmail = "you@example.com";
  aliases = {
    co = "checkout";
    br = "branch";
    st = "status";
    lg = "log --oneline --graph --decorate";
  };
  extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = true;
    push.autoSetupRemote = true;
  };
  signing = {
    key = "ABCDEF1234567890";
    signByDefault = true;
  };
  delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };
};
```

### programs.neovim

```nix
programs.neovim = {
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  plugins = with pkgs.vimPlugins; [
    telescope-nvim
    nvim-treesitter.withAllGrammars
    nvim-lspconfig
  ];
  extraLuaConfig = ''
    vim.opt.number = true
    vim.opt.relativenumber = true
  '';
};
```

### programs.tmux

```nix
programs.tmux = {
  enable = true;
  terminal = "tmux-256color";
  prefix = "C-a";
  baseIndex = 1;
  escapeTime = 0;
  plugins = with pkgs.tmuxPlugins; [
    sensible
    yank
    catppuccin
  ];
  extraConfig = ''
    bind | split-window -h -c "#{pane_current_path}"
    bind - split-window -v -c "#{pane_current_path}"
  '';
};
```

### programs.direnv

```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;  # Caches nix-shell/flake devShells
  enableZshIntegration = true;
};
```

## Terminal

### programs.kitty

```nix
programs.kitty = {
  enable = true;
  font = {
    name = "JetBrains Mono";
    size = 13;
  };
  settings = {
    scrollback_lines = 10000;
    enable_audio_bell = false;
    window_padding_width = 4;
  };
  themeFile = "Catppuccin-Mocha";
};
```

### programs.alacritty

```nix
programs.alacritty = {
  enable = true;
  settings = {
    font = {
      normal.family = "JetBrains Mono";
      size = 13.0;
    };
    window.padding = { x = 4; y = 4; };
  };
};
```

### programs.wezterm

```nix
programs.wezterm = {
  enable = true;
  extraConfig = ''
    return {
      font_size = 13.0,
      color_scheme = "Catppuccin Mocha",
    }
  '';
};
```

### programs.fzf

```nix
programs.fzf = {
  enable = true;
  enableZshIntegration = true;
  defaultCommand = "fd --type f --hidden --follow --exclude .git";
  defaultOptions = [ "--height 40%" "--border" ];
};
```

### programs.bat

```nix
programs.bat = {
  enable = true;
  config.theme = "Catppuccin Mocha";
};
```

### programs.eza

```nix
programs.eza = {
  enable = true;
  enableZshIntegration = true;
  icons = "auto";
  git = true;
};
```

### programs.zoxide

```nix
programs.zoxide = {
  enable = true;
  enableZshIntegration = true;
};
```

## File Management

### home.file — symlink a file

```nix
home.file.".config/wezterm/colors/custom.toml".source = ./dotfiles/custom.toml;
```

### home.file — generate from string

```nix
home.file.".local/bin/my-script" = {
  text = ''
    #!/usr/bin/env bash
    echo "Hello from managed script"
  '';
  executable = true;
};
```

### xdg.configFile — XDG config directory

```nix
xdg.configFile."karabiner/karabiner.json".source = ./dotfiles/karabiner.json;

# Or generate content
xdg.configFile."ripgreprc".text = ''
  --smart-case
  --hidden
  --glob=!.git
'';
```

## Services (Linux Only)

### services.gpg-agent

```nix
services.gpg-agent = {
  enable = true;
  enableSshSupport = true;
  defaultCacheTtl = 3600;
  pinentryPackage = pkgs.pinentry-gnome3;
};
```

### services.syncthing

```nix
services.syncthing = {
  enable = true;
};
```

### services.dunst

```nix
services.dunst = {
  enable = true;
  settings = {
    global = {
      font = "JetBrains Mono 10";
      frame_width = 2;
      corner_radius = 8;
    };
  };
};
```

## Custom Module Pattern

A reusable Home Manager module with its own options:

```nix
# modules/hm/dev-tools.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.custom.devTools;
in
{
  options.custom.devTools = {
    enable = lib.mkEnableOption "custom dev tools bundle";

    gitEmail = lib.mkOption {
      type = lib.types.str;
      description = "Git email for commits";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userEmail = cfg.gitEmail;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.packages = with pkgs; [
      ripgrep
      fd
      jq
    ];
  };
}
```

Usage in `home.nix`:

```nix
{
  imports = [ ./modules/hm/dev-tools.nix ];

  custom.devTools = {
    enable = true;
    gitEmail = "you@example.com";
  };
}
```
