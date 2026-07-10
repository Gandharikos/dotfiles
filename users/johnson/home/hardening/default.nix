{
  inputs,
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.my.hardening;
  enable = osConfig.dot.gui.enable && isLinux && cfg.enable;

  bwraps = pkgs.callPackage ./bwraps { };
  nixpaks = pkgs.callPackage ./nixpaks {
    mkNixPak = inputs.nixpak.lib.nixpak {
      inherit pkgs;
      inherit (pkgs) lib;
    };
  };
in
{
  options.my.hardening = {
    enable = mkEnableOption "per-application sandboxing" // {
      default = osConfig.dot.gui.enable && isLinux;
    };

    apps = {
      wechat.enable = mkEnableOption "sandboxed WeChat" // {
        default = config.my.hardening.enable;
      };

      qq.enable = mkEnableOption "sandboxed QQ" // {
        default = config.my.hardening.enable;
      };
    };
  };

  config = mkIf enable {
    home.packages =
      optionals cfg.apps.wechat.enable [ bwraps.wechat ] ++ optionals cfg.apps.qq.enable [ nixpaks.qq ];
  };
}
