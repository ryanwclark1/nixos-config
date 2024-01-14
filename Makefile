#
#  NOTE: Makefile's target name should not be the same as one of the file or directory in the current directory,
#    otherwise the target will not be executed!
#

# Define the output directory and filenames
RSA_KEY_FILE = ~/.ssh/ssh_host_rsa_key
ED25519_KEY_FILE = ~/.ssh/ssh_host_ed25519_key
AGE_DIR = ~/.config/sops/age
AGE_PUBLIC_KEY_FILE = $(AGE_DIR)/keys.txt

# Define the number of bits for RSA key
RSA_BITS = 4096

# Define the makefile targets and rules
.PHONY: keygen rsa_key ed25519_key age_key get_age_public_key

keygen: rsa_key ed25519_key age_key get_age_public_key

rsa_key:
	@echo "Generating RSA SSH key..."
	@ssh-keygen -t rsa -b $(RSA_BITS) -f $(RSA_KEY_FILE) -N ""

ed25519_key:
	@echo "Generating Ed25519 SSH key..."
	@ssh-keygen -t ed25519 -f $(ED25519_KEY_FILE) -N ""

age_key: create_age_dir
	@echo "Generating Age key pair..."
	@nix --extra-experimental-features nix-command run --extra-experimental-features flakes nixpkgs#ssh-to-age -- -private-key -i $(ED25519_KEY_FILE) > $(AGE_PUBLIC_KEY_FILE)

create_age_dir:
	@echo "Creating Age key directory..."
	@mkdir -p $(AGE_DIR)

get_age_public_key:
	@echo "Getting Age public key..."
	@nix --extra-experimental-features nix-command shell --extra-experimental-features flakes nixpkgs#age -c age-keygen -y $(AGE_PUBLIC_KEY_FILE)



############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

frametop:
	sudo nixos-rebuild switch --flake .#frametop

woody:
	sudo nixos-rebuild switch --flake .#woody

frametop-debug:
	sudo nixos-rebuild switch --flake .#frametop --show-trace --verbose

woody-debug:
	sudo nixos-rebuild switch --flake .#woody --show-trace --verbose

frametop-remote:
	nixos-rebuild switch --flake .#frametop --use-remote-sudo

woody-remote:
	nixos-rebuild switch --flake .#woody --use-remote-sudo

frametop-remote-debug:
	nixos-rebuild switch --flake .#frametop --use-remote-sudo --show-trace --verbose

woody-remote-debug:
	nixos-rebuild switch --flake .#woody --use-remote-sudo --show-trace --verbose

frametop-dryrun:
	sudo nixos-rebuild dry-run --flake .#frametop

woody-dryrun:
	sudo nixos-rebuild dry-run --flake .#woody

up:
	nix flake update

# Update specific input
# usage: make upp i=wallpapers
upp:
	nix flake lock --update-input $(i)

history:
	nix profile history --profile /nix/var/nix/profiles/system

gc:
	# remove all generations older than 7 days
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

	# garbage collect all unused nix store entries
	sudo nix store gc --debug

############################################################################
#
#  Darwin related commands, harmonica is my macbook pro's hostname
#
############################################################################

darwin-set-proxy:
	sudo python3 scripts/darwin_set_proxy.py
	sleep 1

ha: darwin-set-proxy
	nix build .#darwinConfigurations.harmonica.system
	./result/sw/bin/darwin-rebuild switch --flake .
	sleep 1
	sudo chmod 644 /etc/agenix/alias-for-work.*

ha-debug: darwin-set-proxy
	nix build .#darwinConfigurations.harmonica.system --show-trace --verbose
	./result/sw/bin/darwin-rebuild switch --flake .#harmonica --show-trace --verbose
	sleep 1
	sudo chmod 644 /etc/agenix/alias-for-work.*

############################################################################
#
#  Idols, Commands related to my remote distributed building cluster
#
############################################################################

add-idols-ssh-key:
	ssh-add ~/.ssh/ai-idols

idols: add-idols-ssh-key
	colmena apply --on '@dist-build'

aqua:
	colmena apply --on '@aqua'

ruby:
	colmena apply --on '@ruby'

kana:
	colmena apply --on '@kana'

idols-debug: add-idols-ssh-key
	colmena apply --on '@dist-build' --verbose --show-trace

# only used once to setup the virtual machines
idols-image:
	# take image for idols, and upload the image to proxmox nodes.
	nom build .#aquamarine
	scp result root@gtr5:/var/lib/vz/dump/vzdump-qemu-aquamarine.vma.zst

	nom build .#ruby
	scp result root@s500plus:/var/lib/vz/dump/vzdump-qemu-ruby.vma.zst

	nom build .#kana
	scp result root@um560:/var/lib/vz/dump/vzdump-qemu-kana.vma.zst


############################################################################
#
#	RISC-V related commands
#
############################################################################

roll: add-idols-ssh-key
	colmena apply --on '@riscv'

roll-debug: add-idols-ssh-key
	colmena apply --on '@dist-build' --verbose --show-trace

nozomi:
	colmena apply --on '@nozomi'

yukina:
	colmena apply --on '@yukina'

############################################################################
#
# Aarch64 related commands
#
############################################################################

aarch:
	colmena apply --on '@aarch'

suzu:
	colmena apply --on '@suzu'

suzu-debug:
	colmena apply --on '@suzu' --verbose --show-trace

############################################################################
#
#  Misc, other useful commands
#
############################################################################

fmt:
	# format the nix files in this repo
	nix fmt

.PHONY: clean
clean:
	rm -rf result
