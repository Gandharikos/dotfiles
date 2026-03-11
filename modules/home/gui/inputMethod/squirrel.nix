{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my) gui;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  dir = "Library/Rime";
  cfg = gui.system.squirrel;
  # version = "2025.04.06";
  # rime-ice = pkgs.fetchFromGitHub {
  #   owner = "iDvel";
  #   repo = "rime-ice";
  #   tag = version;
  #   hash = "sha256-s3r8cdEliiPnKWs64Wgi0rC9Ngl1mkIrLnr2tIcyXWw=";
  #   fetchSubmodules = false;
  # };
in {
  options.my.gui.system.squirrel = {
    enable =
      mkEnableOption "squirrel"
      // {
        default = true;
      };
  };

  config = mkIf (gui.enable && cfg.enable && isDarwin) {
    home.file = {
      ${dir} = {
        source = "${pkgs.rime-ice}/share/rime-data";
        recursive = true;
        force = true;
      };
      "${dir}/default.yaml".source = "${pkgs.rime-ice}/share/rime-data/rime_ice_suggestion.yaml";
    };

    home.activation.rimeDeploy = lib.hm.dag.entryAfter ["writeBoundary"] ''
      app="/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel"
      "$app" --build  >/dev/null 2>&1 || :
      "$app" --reload >/dev/null 2>&1 || :
    '';
  };
}
