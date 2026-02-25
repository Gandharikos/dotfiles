{inputs, ...}: {
  imports = [inputs.devshell.flakeModule];

  perSystem = {
    pkgs,
    config,
    inputs',
    ...
  }: {
    devshells.default = {
      devshell = {
        name = "dots";
        startup.pre-commit.text = config.pre-commit.installationScript;
      };
      packages = with pkgs;
        [
          nix
          # nix helpers
          nix-melt
          nix-inspect
          nix-search-cli
          # package creation helpers
          nurl
          nix-init
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          inputs'.quickshell.packages.default
        ];
      commands = [
        {
          package = pkgs.nix-tree;
          help = "Interactively browse dependency graphs of Nix derivations";
          category = "nix";
        }
        {
          package = pkgs.nvd;
          help = "Diff two nix toplevels and show which packages were upgraded";
          category = "nix";
        }
        {
          package = pkgs.nix-diff;
          help = "Explain why two Nix derivations differ";
          category = "nix";
        }
        {
          package = pkgs.nix-output-monitor;
          help = "Nix Output Monitor (a drop-in alternative for `nix` which shows a build graph)";
          category = "nix";
        }
        {
          package = pkgs.statix;
          help = "Lint flake";
          category = "nix";
        }
        {
          package = pkgs.deadnix;
          help = "Check flake for dead code";
          category = "nix";
        }
        {
          help = "disko";
          name = "disko";
          command = ''
            ${inputs'.disko.packages.disko}/bin/disko ''${@}
          '';
          category = "dev";
        }
        {
          help = "nixos-anywhere";
          name = "nixos-anywhere";
          command = ''
            ${inputs'.nixos-anywhere.packages.nixos-anywhere}/bin/nixos-anywhere ''${@}
          '';
          category = "dev";
        }
        {
          help = "Generate NixOS configuration with nixos-generators.";
          name = "generate";
          command = "${inputs'.nixos-generators.packages.nixos-generate}/bin/nixos-generate $@";
          category = "dev";
        }
      ];
    };
  };
}
