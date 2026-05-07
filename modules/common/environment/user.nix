{
  config,
  pkgs,
  lib,
  self,
  ...
}:
let
  inherit (config.dot) name home;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) forEach;
  shell = builtins.getAttr config.dot.shell pkgs;
in
{
  environment = {
    # add user's shell into /etc/shells
    shells = with pkgs; [
      bash
      fish
      zsh
    ];
  };

  programs = {
    fish.enable = true;
    zsh.enable = true;
  };

  # Define a user account.
  users.users."${name}" = {
    # https://github.com/LnL7/nix-darwin/issues/1237 still have a bug
    inherit home shell;
    description = name;

    # Public Keys that can be used to login to all hosts;
    openssh.authorizedKeys.keys = [
      # Primary user key
      (builtins.readFile "${self}/secrets/johnson/core/id_ed25519.pub")
    ]
    ++
      # Additional keys from secrets/johnson/core/keys/ (only .pub files)
      (forEach (lib.filter (path: lib.hasSuffix ".pub" (toString path)) (
        listFilesRecursive "${self}/secrets/johnson/core/keys"
      )) (key: builtins.readFile key));
  };
}
