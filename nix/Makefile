.PHONY: sandmhan macman gaia full update clean

sandmhan macman:
	home-manager switch --flake .#$@

gaia:
	sudo nixos-rebuild switch --flake .#$@

full: gaia sandmhan

update:
	nix flake update

clean:
	sudo nix-collect-garbage -d

