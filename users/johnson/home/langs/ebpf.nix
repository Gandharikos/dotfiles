{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.langs.ebpf;
  enable = config.my.langs.enable && cfg.enable;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals;
in
{
  options.my.langs.ebpf = {
    enable = mkEnableOption "eBPF development environment";
  };

  config = mkIf enable {
    home.packages =
      with pkgs;
      optionals stdenv.hostPlatform.isLinux [
        bpftools
        elfutils
        libbpf
        pkg-config
        zlib
      ];

    home.sessionVariables.PKG_CONFIG_PATH = lib.concatStringsSep ":" [
      "${config.home.homeDirectory}/.nix-profile/lib/pkgconfig"
      "${config.home.homeDirectory}/.nix-profile/share/pkgconfig"
      "/run/current-system/sw/lib/pkgconfig"
      "/run/current-system/sw/share/pkgconfig"
    ];
  };
}
