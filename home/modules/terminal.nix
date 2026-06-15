{
  lib,
  pkgs,
  config,
  userSettings,
  ...
}:
let
  cfg = config.myHome;

  tmux-sessionizer = pkgs.writeShellScriptBin "tmux-sessionizer" ''
    if [[ $# -eq 1 ]]; then
        selected=$1
    else
        # Common project directories - adjust these paths to your setup
        selected=$(find ~/code ~/dotfiles ~/work ~/projects -mindepth 1 -maxdepth 2 -type d 2>/dev/null | fzf)
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

    if [[ -z $TMUX ]]; then
        tmux attach-session -t $selected_name
    else
        tmux switch-client -t $selected_name
    fi
  '';
in
{
  # Bash configuration
  programs.bash = {
    enable = true;
    sessionVariables = {
      EDITOR = "nvim";
    };
    initExtra = ''
      export PATH="/home/${userSettings.username}/repos/pi-mono/result/bin:$PATH"
    '';
    shellAliases = {
      ll = "ls -l";
      ".." = "cd ..";
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
    };
    bashrcExtra = "set -o vi";
  };

  # Alacritty terminal emulator
  programs.alacritty = {
    enable = true;
  };

  # Tmux configuration
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;
    shortcut = "a";

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = ''
          # Restore vim sessions
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-strategy-nvim 'session'
          # Restore additional programs
          set -g @resurrect-processes 'ssh psql mysql sqlite3'
          # Restore pane contents
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          # Automatic restore
          set -g @continuum-restore 'on'
          # Save interval (15 minutes)
          set -g @continuum-save-interval '15'
          # Status bar indicator
          set -g @continuum-status-right 'Continuum status: #{continuum_status}'
        '';
      }
    ];

    extraConfig = ''
      	set -g mouse on
      	set -g history-limit 100000
      	unbind C-b
      	set -g prefix C-a
      	bind C-a send-prefix

        # Vim-aware pane navigation via smart-splits.nvim.
        set -g @smart-splits_move_left_key C-h
        set -g @smart-splits_move_down_key C-j
        set -g @smart-splits_move_up_key C-k
        set -g @smart-splits_move_right_key C-l
        set -g @smart-splits_resize_left_key M-h
        set -g @smart-splits_resize_down_key M-j
        set -g @smart-splits_resize_up_key M-k
        set -g @smart-splits_resize_right_key M-l
        run-shell ${pkgs.vimPlugins.smart-splits-nvim}/smart-splits.tmux

        # Resizing Panes
        bind -r h resize-pane -L 5
        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r l resize-pane -R 5

        # Sessionizer keybind
        bind-key -r f run-shell "tmux neww tmux-sessionizer"
    '';
  };

  # Terminal utilities and tools
  home.packages =
    with pkgs;
    [
      tmux-sessionizer
      fzf
    ]
    ++ lib.optionals cfg.features.enableTerminalUtils [
      ripgrep
      fd
      bat
      eza
      tree
      htop
      fastfetch
      unzip
    ]
    ++ lib.optionals cfg.features.enableGitExtensions [
      gitui
      gh
      lazygit
      delta
    ];

  # Advanced shell features
  programs.starship = lib.mkIf cfg.features.enableAdvancedShell {
    enable = true;
    settings = {
      directory.truncation_length = 3;
      git_branch.format = "on [$symbol$branch(:$remote_branch)]($style) ";
      nix_shell = {
        disabled = false;
        format = "via [$symbol$state( \\($name\\))]($style) ";
        impure_msg = "nix dev shell";
        pure_msg = "pure nix dev shell";
        symbol = "❄️ ";
        unknown_msg = "nix dev shell";
      };
    };
  };
  programs.zoxide.enable = lib.mkIf cfg.features.enableAdvancedShell true;

  # Set up home directory and username
  home = {
    username = userSettings.username;
    sessionPath = [
      "/home/${userSettings.username}/repos/pi-mono/result/bin"
    ];
    homeDirectory =
      if cfg.platform.enableLinuxSpecific then
        "/home/${userSettings.username}"
      else if cfg.platform.enableDarwinSpecific then
        "/Users/${userSettings.username}"
      else
        throw "Unsupported platform";

    stateVersion = "24.11";
  };
}
