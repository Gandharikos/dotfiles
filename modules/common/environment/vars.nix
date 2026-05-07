{
  lib,
  _class,
  config,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) str;

in
{
  options.my.flakePath = mkOption {
    type = str;
    default = "/${if (_class == "nixos") then "home" else "Users"}/${config.my.name}/.dotfiles";
    description = "The path to the configuration";
  };

  config.environment.variables = {
    SYSTEMD_PAGERSECURE = "true";

    # Some programs like `nh` use the FLAKE env var to determine the flake path
    FLAKE = config.my.flakePath;
    NH_FLAKE = config.my.flakePath;
  };
}
