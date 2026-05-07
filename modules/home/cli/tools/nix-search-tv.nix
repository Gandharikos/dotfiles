{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals;
  cfg = config.dot.nix-search-tv;
in
{
  options.dot.nix-search-tv = {
    enable = mkEnableOption "nix-search-tv";
  };

  config = mkIf cfg.enable {
    programs.nix-search-tv = {
      # Nix-search-tv documentation
      # See: https://github.com/3timeslazy/nix-search-tv
      enable = true;

      settings = {
        indexes = [
          "nixpkgs"
          "home-manager"
        ]
        ++ optionals pkgs.stdenv.hostPlatform.isLinux [
          "nixos"
        ]
        ++ optionals pkgs.stdenv.hostPlatform.isDarwin [
          "darwin"
        ];
      };
    };
  };
}
