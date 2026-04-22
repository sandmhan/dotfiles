# macOS Defaults via nix-darwin

## System Preferences (`system.defaults.*`)

### Dock

```nix
system.defaults.dock = {
  autohide = true;
  tilesize = 48;
  orientation = "bottom"; # "left", "bottom", "right"
  show-recents = false;
  minimize-to-application = true;
  mru-spaces = false; # disable auto-rearrange Spaces
};
```

### Finder

```nix
system.defaults.finder = {
  AppleShowAllExtensions = true;
  FXPreferredViewStyle = "Nlsv"; # list view ("icnv", "clmv", "glyv")
  ShowPathbar = true;
  _FXShowPosixPathInTitle = true;
  FXEnableExtensionChangeWarning = false;
};
```

### NSGlobalDomain

```nix
system.defaults.NSGlobalDomain = {
  AppleShowAllExtensions = true;
  AppleInterfaceStyle = "Dark"; # set to null for light mode
  InitialKeyRepeat = 15; # default 25 (lower = faster)
  KeyRepeat = 2; # default 6 (lower = faster)
  NSAutomaticCapitalizationEnabled = false;
  NSAutomaticSpellingCorrectionEnabled = false;
  NSAutomaticDashSubstitutionEnabled = false;
  NSAutomaticQuoteSubstitutionEnabled = false;
  "com.apple.swipescrolldirection" = true; # natural scrolling
};
```

### Trackpad

```nix
system.defaults.trackpad = {
  Clicking = true; # tap to click
  TrackpadRightClick = true; # two-finger right click
  TrackpadThreeFingerDrag = true;
};
```

### Login Window

```nix
system.defaults.loginwindow = {
  GuestEnabled = false;
  DisableConsoleAccess = true;
};
```

### Screen Capture

```nix
system.defaults.screencapture = {
  location = "~/Screenshots";
  type = "png"; # "png", "jpg", "pdf", "tiff"
};
```

### Screen Saver

```nix
system.defaults.screensaver = {
  askForPassword = true;
  askForPasswordDelay = 5; # seconds
};
```

### Custom User Preferences

For any `defaults write` domain not covered above:

```nix
system.defaults.CustomUserPreferences = {
  "com.apple.desktopservices" = {
    DSDontWriteNetworkStores = true;
    DSDontWriteUSBStores = true;
  };
  "com.apple.AdLib" = {
    allowApplePersonalizedAdvertising = false;
  };
};
```

## Security (`security.*`)

### Touch ID for sudo

```nix
security.pam.services.sudo_local.touchIdAuth = true;
```

This survives macOS updates (uses `/etc/pam.d/sudo_local`).

## Homebrew Integration (`homebrew.*`)

Use for GUI apps and Mac App Store apps not available in nixpkgs.

```nix
homebrew = {
  enable = true;

  # CLI formulae
  brews = [
    "mas" # Mac App Store CLI
  ];

  # GUI applications
  casks = [
    "raycast"
    "figma"
    "1password"
  ];

  # Mac App Store apps (requires `mas` and being signed in)
  masApps = {
    "Xcode" = 497799835;
    "Amphetamine" = 937984704;
  };

  # Remove formulae/casks not listed above on activation
  onActivation = {
    cleanup = "zap"; # "none", "uninstall", "zap"
    autoUpdate = true;
    upgrade = true;
  };
};
```

**When to use Homebrew via nix-darwin**: GUI apps that need macOS code signing or aren't packaged in nixpkgs (e.g., Raycast, Figma, 1Password). Prefer nixpkgs for CLI tools.

## Launchd Services (`launchd.user.agents.*`)

Define user-level launchd agents (run on login):

```nix
launchd.user.agents.my-daemon = {
  serviceConfig = {
    Label = "com.user.my-daemon";
    ProgramArguments = [
      "/usr/local/bin/my-daemon"
      "--flag"
    ];
    RunAtLoad = true;
    KeepAlive = true;
    StandardOutPath = "/tmp/my-daemon.stdout.log";
    StandardErrorPath = "/tmp/my-daemon.stderr.log";
  };
};
```

For system-level daemons (run as root), use `launchd.daemons.*` with the same structure.

## Environment (`environment.*`)

### System Packages

```nix
environment.systemPackages = with pkgs; [
  coreutils
  curl
  git
  jq
  ripgrep
];
```

### Shells

```nix
environment.shells = with pkgs; [
  bashInteractive
  zsh
];
programs.zsh.enable = true; # required for nix-darwin PATH integration
```

### Environment Variables

```nix
environment.variables = {
  EDITOR = "nvim";
  LANG = "en_US.UTF-8";
};
```

### System PATH

```nix
environment.systemPath = [
  "/opt/homebrew/bin"
];
```

This prepends to PATH for all users and shells.
