# Agent VM Tools Configuration - Development and Debugging Tools
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Essential development packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    curl
    wget
    jq
    yq
    tree
    htop
    btop
    fastfetch
    unzip
    zip
    rsync

    # Nix tools
    nixfmt-rfc-style
    nix-tree
    nix-output-monitor
    manix
    nix-index

    # Development tools
    gnumake
    gcc
    nodejs_20
    python3
    go

    # Container and virtualization tools
    docker-compose
    dive # Docker image analysis
    ctop # Container monitoring
    lazydocker # Docker TUI

    # Network debugging
    netcat-gnu
    nmap
    dig
    whois
    tcpdump
    wireshark-cli
    iperf3
    mtr
    traceroute

    # System monitoring
    lsof
    strace
    iotop
    nethogs
    ncdu
    fd
    ripgrep
    fzf

    # Text processing
    vim
    nano
    bat
    less
    gnugrep
    gnused
    gawk

    # File management
    ranger
    mc # Midnight Commander
    eza # Modern ls

    # Archive tools
    p7zip
    gnutar
    gzip
    bzip2
    xz
  ];

  # Tmux configuration with sessionizer and resurrect
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    historyLimit = 50000;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    escapeTime = 0;

    extraConfig = ''
      # Better colors
      set-option -sa terminal-overrides ",xterm*:Tc"

      # Mouse support
      set -g mouse on

      # Start windows and panes at 1, not 0
      set -g base-index 1
      setw -g pane-base-index 1

      # Renumber windows when one is closed
      set -g renumber-windows on

      # Use Alt-arrow keys without prefix key to switch panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift arrow to switch windows
      bind -n S-Left  previous-window
      bind -n S-Right next-window

      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Reload config file
      bind r source-file ~/.tmux.conf \; display "Config reloaded!"

      # Status bar styling
      set -g status-bg black
      set -g status-fg white
      set -g status-left-length 50
      set -g status-right-length 50
      set -g status-left '#[fg=green]Agent VM #[fg=blue]#S '
      set -g status-right '#[fg=yellow]#(uptime | cut -d"," -f1) #[fg=green]%H:%M %d-%b'

      # Pane border colors
      set -g pane-border-style fg=colour8
      set -g pane-active-border-style fg=colour2

      # Activity monitoring
      setw -g monitor-activity on
      set -g visual-activity off

      # Auto-restore tmux sessions
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-strategy-nvim 'session'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-restore 'on'
      set -g @continuum-boot 'on'
      set -g @continuum-save-interval '15'

      # Sessionizer binding
      bind-key f run-shell "tmux neww ~/.local/bin/tmux-sessionizer"
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
    ];
  };

  # Install tmux sessionizer script
  environment.etc."tmux-sessionizer" = {
    source = pkgs.writeShellScript "tmux-sessionizer" ''
      #!/usr/bin/env bash

      if [[ $# -eq 1 ]]; then
          selected=$1
      else
          selected=$(find ~/workspace ~/templates ~/scripts ~/.config -mindepth 1 -maxdepth 1 -type d | fzf)
      fi

      if [[ -z $selected ]]; then
          exit 0
      fi

      selected_name=$(basename "$selected" | tr . _)
      tmux_running=$(pgrep tmux)

      if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
          tmux new-session -s $selected_name -c $selected
          exit 0
      fi

      if ! tmux has-session -t=$selected_name 2> /dev/null; then
          tmux new-session -ds $selected_name -c $selected
      fi

      tmux switch-client -t $selected_name
    '';
    mode = "0755";
  };

  # Symlink sessionizer to user bin
  systemd.tmpfiles.rules = [
    "L /home/agent/.local/bin/tmux-sessionizer - - - - /etc/tmux-sessionizer"
    "d /home/agent/.local/bin 0755 agent agent -"
  ];

  # Git configuration for agent user
  programs.git = {
    enable = true;
    config = {
      user = {
        name = "Agent VM";
        email = "agent@homelab.local";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "vim";
        autocrlf = false;
      };
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
    };
  };

  # Shell configuration
  programs.bash = {
    enable = true;
    interactiveShellInit = ''
      # Agent VM specific aliases and functions
      alias ll='eza -la'
      alias ls='eza'
      alias grep='rg'
      alias cat='bat'
      alias top='btop'
      alias htop='btop'

      # Development shortcuts
      alias nix-build-dry='nix build --dry-run'
      alias nix-flake-check='nix flake check'
      alias nix-fmt='nixfmt .'
      alias docker-clean='docker system prune -af'

      # Navigation functions
      workspace() {
        cd ~/workspace
        if [[ -n "$1" ]]; then
          cd "$1"
        fi
      }

      # Tmux session management
      tnew() {
        tmux new-session -d -s "$1" -c "$(pwd)"
        tmux switch-client -t "$1" 2>/dev/null || tmux attach -t "$1"
      }

      tlist() {
        tmux list-sessions
      }

      tattach() {
        tmux attach -t "$1"
      }

      # Quick directory creation and navigation
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # Agent-specific functions
      agent-status() {
        echo "=== Agent VM Status ==="
        echo "Uptime: $(uptime -p)"
        echo "Disk Usage:"
        df -h /
        echo "Memory Usage:"
        free -h
        echo "Running Containers:"
        docker ps 2>/dev/null || echo "Docker not available"
        echo "Active tmux sessions:"
        tmux list-sessions 2>/dev/null || echo "No tmux sessions"
      }

      # Claude Code helpers
      claude-workspace() {
        cd ~/workspace
        if [[ -n "$1" ]]; then
          cd "$1"
          claude --dir "$(pwd)"
        else
          claude --dir ~/workspace
        fi
      }

      # Set up prompt
      export PS1='\[\033[01;32m\]agent@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

      # History settings
      export HISTSIZE=10000
      export HISTFILESIZE=20000
      export HISTCONTROL=ignoredups:erasedups
      shopt -s histappend

      # FZF configuration
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    '';
  };

  # Auto-start tmux for agent user
  systemd.user.services.tmux-autostart = {
    description = "Auto-start tmux session for agent";
    wantedBy = [ "default.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -s main -c /home/agent/workspace";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-server";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Environment variables for development
  environment.variables = {
    EDITOR = "vim";
    PAGER = "less -R";
    TERM = "xterm-256color";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  # Localization
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
}
