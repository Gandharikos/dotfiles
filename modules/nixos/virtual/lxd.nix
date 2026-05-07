# Inspired by https://www.srid.ca/2012301.html
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dot.virtual.lxd;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
in
{
  options.dot.virtual.lxd = {
    enable = mkEnableOption "Enable LXD" // {
      default = config.dot.virtual.enable;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeScriptBin "lxc-build-nixos-image" ''
        #!/usr/bin/env nix-shell
        #!nix-shell -i bash -p nixos-generators
        set -xe
        config=$1
        metaimg=`nixos-generate -f lxc-metadata \
          | xargs -r cat \
          | awk '{print $3}'`
        img=`nixos-generate -c $config -f lxc \
          | xargs -r cat \
          | awk '{print $3}'`
        lxc image import --alias nixos $metaimg $img
      '')
    ];
  };
}
