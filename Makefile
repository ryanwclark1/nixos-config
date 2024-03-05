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
	@if [ ! -f $(RSA_KEY_FILE) ] || (read -p "RSA SSH key already exists. Do you want to overwrite it? [y/N] " answer; [ "$$answer" == "y" ]); then \
		echo "Generating RSA SSH key..."; \
		ssh-keygen -t rsa -b $(RSA_BITS) -f $(RSA_KEY_FILE) -N ""; \
	else \
		echo "Skipping RSA SSH key generation..."; \
	fi

ed25519_key:
	@if [ ! -f $(ED25519_KEY_FILE) ] || (read -p "Ed25519 SSH key already exists. Do you want to overwrite it? [y/N] " answer; [ "$$answer" == "y" ]); then \
		echo "Generating Ed25519 SSH key..."; \
		ssh-keygen -t ed25519 -f $(ED25519_KEY_FILE) -N ""; \
	else \
		echo "Skipping Ed25519 SSH key generation..."; \
	fi

age_key: create_age_dir
	@if [ ! -f $(AGE_PUBLIC_KEY_FILE) ] || (read -p "Age key pair already exists. Do you want to overwrite it? [y/N] " answer; [ "$$answer" == "y" ]); then \
		echo "Generating Age key pair..."; \
		nix --extra-experimental-features nix-command run --extra-experimental-features flakes nixpkgs#ssh-to-age -- -private-key -i $(ED25519_KEY_FILE) > $(AGE_PUBLIC_KEY_FILE); \
	else \
		echo "Skipping Age key pair generation..."; \
	fi

create_age_dir:
	@if [ ! -d $(AGE_DIR) ]; then \
		echo "Creating Age key directory..."; \
		mkdir -p $(AGE_DIR); \
	fi

get_age_public_key:
	@if [ -f $(AGE_PUBLIC_KEY_FILE) ]; then \
		echo "Getting Age public key..."; \
		nix --extra-experimental-features nix-command shell --extra-experimental-features flakes nixpkgs#age -c age-keygen -y $(AGE_PUBLIC_KEY_FILE); \
	else \
		echo "Age public key does not exist. Skipping..."; \
	fi

###########################################################################
#
#  Make PGP
#
############################################################################

.PHONY: pgp

# Not working!!!
pgp:
	@echo "Make PGP key..."
	nix --extra-experimental-features nix-command shell --extra-experimental-features flakes nixpkgs#gpg --full-generate-key


###########################################################################
#
#  Get sha256 hash of a VSIX package
#
############################################################################

.PHONY: get-vscode-sha

get-vscode-sha:
	@read -p "Enter Publisher: " PUBLISHER; \
	read -p "Enter Extension Name: " EXTENSION; \
	read -p "Enter Version: " VERSION; \
	URL="https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/$$PUBLISHER/extension/$$EXTENSION/$$VERSION/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"; \
	echo "Checking URL $$URL..."; \
	HTTP_STATUS=$$(curl -o /dev/null -L --silent --write-out '%{http_code}\n' $$URL); \
	if [ $$HTTP_STATUS -eq 200 ]; then \
		echo "URL is valid. Calculating SHA256 for $$EXTENSION version $$VERSION from $$PUBLISHER..."; \
		SHA256_HASH=$$(curl -sL $$URL | openssl dgst -sha256 -binary | openssl base64); \
		echo "{"; \
		echo "  name = \"$$EXTENSION\";"; \
		echo "  publisher = \"$$PUBLISHER\";"; \
		echo "  version = \"$$VERSION\";"; \
		echo "  sha256 = \"sha256-$$SHA256_HASH\";"; \
		echo "}"; \
	else \
		echo "Error: The URL is not valid or the file does not exist. HTTP Status: $$HTTP_STATUS"; \
	fi

###########################################################################
#
#  Make Secrets
#
############################################################################

# Not working!!!!
.PHONY: secrets

secrets:
	@echo "Enter the path where the encrypted secrets.yaml file will be saved: "
	@read SECRETS_PATH; \
	if [ "$${SECRETS_PATH:0:1}" != "/" ]; then \
		SECRETS_PATH="$(CURDIR)/$$SECRETS_PATH"; \
	fi; \
	DIR_PATH=$$(dirname $$SECRETS_PATH); \
	if [ ! -d "$$DIR_PATH" ]; then \
		echo "The directory $$DIR_PATH does not exist. Do you want to create it? [y/N]:"; \
		read CONFIRM; \
		if [ "$$CONFIRM" != "y" ] && [ "$$CONFIRM" != "Y" ]; then \
			echo "Exiting. Directory not created."; \
			exit 1; \
		fi; \
		mkdir -p $$DIR_PATH; \
		echo "Directory $$DIR_PATH created."; \
	fi; \
	echo "The encrypted secrets.yaml will be created at: $$SECRETS_PATH"; \
	cd $$SECRETS_PATH
	echo "Creating and encrypting secrets.yaml..."; \
	nix --experimental-features 'nix-command flakes' run nixpkgs#sops secrets.yaml \
	echo "Encrypted secrets.yaml created at: $$SECRETS_PATH"


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
	@echo "Enter machine name to rebuild and clean boot menu: "
	@read MACHINE_NAME; \
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d \
	# garbage collect all unused nix store entries
	sudo nix store gc --debug \
	sudo nix-collect-garbage --delete-older-than 7d \
	# TODO: fix variable with #
	sudo nixos-rebuild boot --flake .#$$MACHINE_NAME;



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
#  Misc, other useful commands
#
############################################################################

fmt:
	# format the nix files in this repo
	nix fmt

.PHONY: clean
clean:
	rm -rf result
