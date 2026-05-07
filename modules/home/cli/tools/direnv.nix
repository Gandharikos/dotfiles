{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.direnv;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  direnvPackage =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.direnv.overrideAttrs (_: {
        # The Darwin build currently stalls in the upstream zsh-based test suite.
        # Keep the other upstream checks enabled.
        checkPhase = ''
          runHook preCheck

          make test-go test-bash test-fish

          runHook postCheck
        '';
      })
    else
      pkgs.direnv;
in
{
  options.dot.direnv = {
    enable = mkEnableOption "direnv";
    silent = mkEnableOption "silent";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      package = direnvPackage;

      inherit (cfg) silent;

      # faster, persistent implementation of use_nix and use_flake in
      # direnv based shells.
      nix-direnv.enable = true;

      config.global = {
        hide_env_diff = true;
      };
    };
  };
}
