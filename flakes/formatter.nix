{inputs, ...}: {
  imports = [inputs.treefmt.flakeModule];
  perSystem = {config, ...}: {
    formatter = config.treefmt.build.wrapper;
    treefmt = {
      # package = pkgs.treefmt;
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        deadnix.enable = true;
        prettier.enable = true;
        statix.enable = true;
        stylua.enable = true;
        yamlfmt.enable = true;
        shfmt.enable = true;
        shellcheck.enable = true;
        actionlint.enable = true;
        keep-sorted.enable = true;
        taplo.enable = true;
      };

      settings = {
        on-unmatched = "info";
        tree-root-file = "flake.nix";

        global.excludes = [
          "LICENSE"
          # unsupported extensions
          "*.{gif,png,jpg,svg,tape,mts,lock,mod,sum,toml,env,envrc,gitignore,age,pub}"
          "secrets/*"
        ];
        formatter = {
          deadnix = {priority = 1;};

          statix = {priority = 2;};

          alejandra = {priority = 3;};

          prettier = {
            settings = {
              write = true; # Automatically format files
              configPath = "../.prettierrc.yaml"; # relative to the flake root
            };
            includes = ["*.{css,html,js,json,jsx,md,mdx,scss,ts,yaml}"];
          };
          shellcheck = {
            options = ["--external-sources" "--source-path=SCRIPTDIR"];
            excludes = ["gdb/*" "zsh/*"];
          };
          shfmt = {
            includes = ["*.envrc" "*.zshrc"];
            excludes = ["gdb/*" "zsh/*"];
          };
          actionlint = {
            includes = [
              ".github/workflows/*.yml"
              ".github/workflows/*.yaml"
            ];
          };
          keep-sorted = {
            includes = ["*"];
          };
          taplo = {
            options = ["format"];
            includes = ["*.toml"];
          };
          yamlfmt = {
            includes = ["*.yml" "*.yaml"];
          };
        };
      };
    };
    devshells.default = {
      commands = [
        {
          package = config.treefmt.build.wrapper;
          help = "Format all files";
          category = "nix";
        }
      ];
    };
  };
}
