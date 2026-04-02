{
  ...
}:
{

  programs.bash = {
    enable = true;
    sessionVariables = {
      EDITOR = "nvim";
    };
    shellAliases = {
      ll = "ls -l";
      ".." = "cd ..";
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
    };

    bashrcExtra = "set -o vi";
  };

  programs.alacritty = {
    enable = true;
  };

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

        # Pane Navigation
      	bind -n C-h select-pane -L
      	bind -n C-j select-pane -D
      	bind -n C-k select-pane -U
      	bind -r j resize-pane -D 5
      	bind -n C-k select-pane -U
      	bind -n C-l select-pane -R

        # Resizing Panes
        bind -r h resize-pane -L 5
        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r l resize-pane -R 5

        # Sessionizer keybind
        bind-key -r f run-shell "tmux neww tmux-sessionizer"
    '';
    # extraConfig = builtins.readFile "github:sandmhan/dotfiles/nix/config/.tmux.conf";
  };
}
