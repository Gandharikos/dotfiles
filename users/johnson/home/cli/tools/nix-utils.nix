{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my.nix-utils;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;

  templateInit = pkgs.writeShellApplication {
    name = "init";
    runtimeInputs = [ pkgs.omnix ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: init <output-directory>" >&2
        exit 2
      fi

      exec om init "${config.home.homeDirectory}/.dotfiles" --output "$1"
    '';
  };
in
{
  options.my.nix-utils = {
    enable = mkEnableOption "nix-utils" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # ======== Nix Development Tools ========
    home.packages = with pkgs; [
      templateInit
      devenv # Declarative development environments
      nixd # Nix LSP
      nil # Nix LSP
      nixfmt # RFC style formatter
      nvd # Nix differ
      nix-diff # Another differ
      nix-output-monitor # Better nix build output
      nh # Nix helper
      omnix # Interactive Nix flake template initialization
      nurl # Generate nix fetcher calls
      nix-prefetch-github # Fetch GitHub repo hash
      statix
    ];

    programs = {
      nh = {
        enable = true;
        flake = "${config.home.homeDirectory}/.dotfiles";
        clean = {
          enable = true;
          dates = "monthly";
          extraArgs = "--keep 5 --keep-since 1m";
        };
      };

      nix-init = {
        enable = true;
        settings = {
          maintainers = [ "mulatta" ];
          nixpkgs = "<nixpkgs>";
        };
      };
    };
  };
}
