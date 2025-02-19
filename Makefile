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

# Generate AGE pair
# nix-shell -p age --run 'age-keygen -o ~/.config/sops/age/key.txt'
# Note: age-keygen -y ~/.config/sops/age/key.txt gives you the public output
# nix-shell -p ssh-to-age --run 'cat ~/.ssh/ssh_host_ed25519_key.pub | ssh-to-age'

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

ssh_to_age:
	@if [ ! -f $(ED25519_KEY_FILE) ] || (read -p "Ed25519 SSH key exists. Do you want to create a AGE key? [y/N] " answer; [ "$$answer" == "y" ]); then \
		echo "Generating AGE from Ed25519 SSH key..."; \
		cat $(ED25519_KEY_FILE) | ; \
	else \
		echo "Skipping SSH-TO_AGE key conversion..."; \
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

get-vscode-extension-sha:
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


get-vscode-sha:
	@read -p "Enter Platform (linux-x64, linux-arm64, darwin-arm64): " PLAT; \
	read -p "Enter Version: " VERSION; \
	URL="https://update.code.visualstudio.com/$$VERSION/$$PLAT/stable"; \
	echo "Checking URL $$URL..."; \
	HTTP_STATUS=$$(curl -o /dev/null -L --silent --write-out '%{http_code}\n' $$URL); \
	if [ $$HTTP_STATUS -eq 200 ]; then \
		echo "URL is valid. Calculating SHA256 for VSCode version $$VERSION on $$PLAT..."; \
		SHA256_HASH=$$(curl -sL $$URL | sha256sum); \
		echo "{"; \
		echo "  plat = \"$$PLAT\";"; \
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

switch:
	sudo nixos-rebuild switch --flake .#$(i) --show-trace --verbose

woody:
	sudo nixos-rebuild switch --flake .#woody --show-trace --verbose

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
	$(eval MACHINE_NAME := $(shell hostname))
	@echo "Machine Name: $$MACHINE_NAME"
	echo "Wiping profile history older than 7 days..."; \
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d; \
	echo "Running garbage collection..."; \
	sudo nix store gc; \
	echo "Deleting old generations of garbage..."; \
	sudo nix-collect-garbage --delete-older-than 7d; \
	echo "Rebuilding NixOS for machine $$MACHINE_NAME..."; \
	sudo nixos-rebuild boot --flake .#$$MACHINE_NAME


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
