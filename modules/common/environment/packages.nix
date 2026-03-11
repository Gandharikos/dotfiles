{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # keep-sorted start
    cmake
    coreutils
    curl
    git
    git-lfs
    gnumake
    just # use Justfile to simplify nix-darwin's commands
    neovim
    nix-prefetch-git
    rsync
    uutils-coreutils-noprefix
    wget
    # keep-sorted end
  ];
}
