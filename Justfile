set shell := ["bash", "-c"]
rebuild := if os() == "macos" { "sudo darwin-rebuild" } else { "sudo nixos-rebuild" }
build_config := if os() == "macos" { "darwinConfigurations" } else { "nixosConfigurations" }

# List all the just commands
default:
  @just --list --unsorted

# Build the system configuration
[group('nix')]
build host=`uname -n`:
  nix build .#{{build_config}}.{{host}}.system --extra-experimental-features "nix-command flakes" --show-trace --verbose

# Rebuild specific host using nh
[group('nix')]
switch host=`uname -n`:
  nh {{ if os() == "macos" { "darwin" } else { "os" } }} switch . -v -H {{host}} --ask

# Classic cmmand to rebuild nixos
[group('nix')]
switch2 host=`uname -n`:
  {{rebuild}} switch --flake .#{{host}} --show-trace -L -v

# Roll back to the previous system generation
[group('nix')]
rollback host=`uname -n`:
  {{rebuild}} switch --rollback --flake .#{{host}} --show-trace -L -v

# Deploy the system configuration to a remote host
[group('nix')]
deploy host *args:
  deploy .#{{host}} --skip-checks --remote-build {{args}}

# Install nixos on a machine with an existing operating system
[group('nix')]
install host *args:
  nixos-anywhere \
    --flake .#{{host}} \
    --copy-host-keys \
    --build-on remote root@{{host}} {{args}}

# Install nixos on a machine with no operating system
[group('nix')]
install2 host ip *args:
  nixos-anywhere  \
    --flake .#{{host}} \
    --copy-host-keys \
    --build-on remote nixos@{{ip}} {{args}}

# Create disks and install nixos
# args can use specific mrrior url --option substituters "https://mirror.sjtu.edu.cn/nix-channels/store"
[group('nix')]
disko host *args:
  sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode disko \
    --flake .#{{host}}
  nixos-install --flake .#{{host}} {{args}}

# Remove all generations order than 7 days
# on darwin, you may need to switch to root user to run this command
[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# Garbage collect all unused nix store entries
[group('nix')]
gc:
  # garbage collect all unused nix store entries(system-wide)
  nix-collect-garbage --delete-older-than 7d
  nix store optimise

# Update all or specific flake inputs.
# If no inputs are provided, all flake inputs will be updated.
# Usage: just update [input1] [input2]...
[group('nix')]
update *inputs:
  nix flake update {{inputs}}

# List all generations of the system profile
[group('nix')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
[group('nix')]
repl:
  nix repl -f flake:nixpkgs

# Check the flake
[group('nix')]
check *args:
  nix flake check {{args}}
  statix check .

# Create a clean and simple shell with git and neovim
[group('nix')]
shell:
  nix shell nixpkgs#git nixpkgs#neovim

# Open my develop shell whicih is defined in this repo
[group('nix')]
dev name="default":
  nix develop .#{{name}}

# Format the nix files in this repo
[group('nix')]
fmt:
  # format the nix files in this repo
  nix fmt

# Show all the auto gc roots in the nix store
[group('nix')]
gcroot:
  ls -al /nix/var/nix/gcroots/auto/

# Reload nix direnv
[group('nix')]
reload:
  nix-direnv-reload

# Verify all the store entries
# Nix Store can contains corrupted entries if the nix store object has been modified unexpectedly.
# This command will verify all the store entries,
# and we need to fix the corrupted entries manually via `sudo nix store delete <store-path-1> <store-path-2> ...`
[group('nix')]
verify:
  nix store verify --all

# Repair Nix Store Objects
[group('nix')]
repair *paths:
  nix store repair {{paths}}

# Remove this program's configuration folder
[group('dev')]
rm program:
  rm -rf "$HOME/.config/{{program}}"

# Move this program's configuration folder from my repo to the config folder for devvelopment
[group('dev')]
cfg program:
  just rm {{program}}
  rsync -avz --copy-links config/{{program}}/ "$HOME/.config/{{program}}/"

# Backup this program's configuration folder to my repo
[group('dev')]
add program:
  rm -rf config/{{program}}/
  mv "$HOME/.config/{{program}}" config/

# Decrypt core secrets using PGP (requires Yubikey)
[group('secret')]
decrypt host=`uname -n`:
  mkdir -p ~/.ssh
  sops -d --extract '["data"]' secrets/core/id_ed25519.yaml > ~/.ssh/id_ed25519
  chmod 600 ~/.ssh/id_ed25519
  sudo mkdir -p /etc/ssh
  sops -d --extract '["data"]' secrets/core/{{host}}.yaml | sudo tee /etc/ssh/ssh_host_ed25519_key > /dev/null
  sudo chmod 600 /etc/ssh/ssh_host_ed25519_key

# Decrypt and copy keys to a remote host
[group('secret')]
init-remote host ip:
  @mkdir -p /tmp/keys-{{host}}
  sops -d --extract '["data"]' secrets/core/id_ed25519.yaml > /tmp/keys-{{host}}/id_ed25519
  cp secrets/core/id_ed25519.pub /tmp/keys-{{host}}/id_ed25519.pub
  sops -d --extract '["data"]' secrets/core/{{host}}.yaml > /tmp/keys-{{host}}/ssh_host_ed25519_key
  cp secrets/core/{{host}}.pub /tmp/keys-{{host}}/ssh_host_ed25519_key.pub
  chmod 600 /tmp/keys-{{host}}/id_ed25519 /tmp/keys-{{host}}/ssh_host_ed25519_key
  ssh johnson@{{ip}} "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
  scp /tmp/keys-{{host}}/id_ed25519 /tmp/keys-{{host}}/id_ed25519.pub johnson@{{ip}}:~/.ssh/
  scp /tmp/keys-{{host}}/ssh_host_ed25519_key /tmp/keys-{{host}}/ssh_host_ed25519_key.pub johnson@{{ip}}:~/
  ssh -t johnson@{{ip}} "sudo mkdir -p /etc/ssh /persist/etc/ssh && \
    sudo cp ~/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key && \
    sudo cp ~/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key.pub && \
    sudo cp ~/ssh_host_ed25519_key /persist/etc/ssh/ssh_host_ed25519_key && \
    sudo cp ~/ssh_host_ed25519_key.pub /persist/etc/ssh/ssh_host_ed25519_key.pub && \
    sudo chmod 600 /etc/ssh/ssh_host_ed25519_key /persist/etc/ssh/ssh_host_ed25519_key && \
    sudo chmod 644 /etc/ssh/ssh_host_ed25519_key.pub /persist/etc/ssh/ssh_host_ed25519_key.pub && \
    rm ~/ssh_host_ed25519_key*"
  # initialize nix profile directory for home-manager
  ssh -t johnson@{{ip}} "sudo mkdir -p /nix/var/nix/profiles/per-user/johnson /persist/nix/var/nix/profiles/per-user/johnson && \
    sudo chown johnson:users /nix/var/nix/profiles/per-user/johnson /persist/nix/var/nix/profiles/per-user/johnson && \
    sudo chmod 755 /nix/var/nix/profiles/per-user/johnson /persist/nix/var/nix/profiles/per-user/johnson"
  # user ssh key persistence
  ssh johnson@{{ip}} "mkdir -p ~/.ssh /persist/home/johnson/.ssh && chmod 700 ~/.ssh /persist/home/johnson/.ssh"
  scp /tmp/keys-{{host}}/id_ed25519 /tmp/keys-{{host}}/id_ed25519.pub johnson@{{ip}}:~/.ssh/
  ssh johnson@{{ip}} "cp ~/.ssh/id_ed25519* /persist/home/johnson/.ssh/ && chmod 600 ~/.ssh/id_ed25519 /persist/home/johnson/.ssh/id_ed25519"
  @rm -rf /tmp/keys-{{host}}

[group('misc')]
ssh-init:
  sudo ssh-keygen -A
