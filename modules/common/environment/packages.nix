{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # editor
    neovim
    git
    git-lfs
    wget
    curl
    just # use Justfile to simplify nix-darwin's commands
    rsync
    cmake
    gnumake
    # darwin only apps
    coreutils
    # nix
    nix-prefetch-git
    # GNU core utilities (rewritten in rust)
    uutils-coreutils-noprefix
  ];
}
