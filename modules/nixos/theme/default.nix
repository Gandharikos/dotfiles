{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib) filterAttrs genAttrs;
  inherit (lib.dot) relativeToConfig;
  inherit (lib.modules) mkDefault mkMerge;

  targetNames = builtins.attrNames (
    filterAttrs (_name: type: type == "directory") (builtins.readDir "${inputs.nixporn}/modules/nixos")
  );
in
{
  imports = [
    inputs.nixporn.nixosModules.colorscheme
  ]
  ++ lib.dot.scanPaths ./.;

  config = mkMerge [
    {
      nixporn = {
        enable = mkDefault true;
        colorscheme = mkDefault "tokyonight";
        transparent = mkDefault true;
        avatar = mkDefault (if config.dot.gui.enable then relativeToConfig "avatars/makima.jpg" else null);
        wallpaper = mkDefault null;
      }
      // genAttrs targetNames (name: {
        enable = mkDefault (name == "tty");
      });
    }
  ];
}
