.PHONY: sandmhan macman wslman terminalman gaia full update clean

# Home Manager configurations
sandmhan macman wslman terminalman:
	home-manager switch --flake .#$@

gaia:
	sudo nixos-rebuild switch --flake .#$@

full: gaia sandmhan

update:
	nix flake update

clean:
	sudo nix-collect-garbage -d

