{
  description = "Sandmhan's Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.05";
    };

		nixvim = {
			url = "github:nix-community/nixvim/nixos-25.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      stylix,
			nixvim,
      ...
    }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      # ---- SYSTEM SETTINGS ---- #
      systemSettings = {
        system = "x86_64-linux"; # system arch
        hostname = "gaia"; # hostname
        profile = "personal"; # select a profile defined from my profiles directory
        timezone = "America/Chicago"; # select timezone
        locale = "en_US.UTF-8"; # select locale
        bootMode = "uefi"; # uefi or bios
        bootMountPath = "/boot"; # mount path for efi boot partition; only used for uefi boot mode
        grubDevice = ""; # device identifier for grub; only used for legacy (bios) boot mode
        gpuType = "amd"; # amd, intel or nvidia; only makes some slight mods for amd at the moment
      };

      # ----- USER SETTINGS ----- #
      userSettings = {
        username = "sandmhan";
				email = "austinsanders0105@gmail.com";
        theme = "";
        wm = "hyprland"; # Selected window manager or desktop environment; must select one in both ./user/wm/ and ./system/wm/
				font = "Blex Mono"; # Font from Nerdfonts list
      };
    in
    {

      # System Configuration Output
      nixosConfigurations = {
        gaia = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            # stylix.nixosModules.stylix
          ];
        };
      };

      # User Configuration Output
      homeConfigurations = {
        # configuration name matches with hostname
        sandmhan = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            #stylix.nixosModules.stylix
						nixvim.homeManagerModules.nixvim
          ];

          # Passing in configuration variables from above
          extraSpecialArgs = {
            inherit userSettings;
						inherit nixvim;
          };
        };
      };
    };
}
