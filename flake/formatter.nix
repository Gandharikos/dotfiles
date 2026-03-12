{inputs, ...}: {
  imports = [inputs.treefmt.flakeModule];
  perSystem = {config, ...}: {
    formatter = config.treefmt.build.wrapper;
    treefmt = {
      # package = pkgs.treefmt;
      projectRootFile = "flake.nix";
      programs = {
        # keep-sorted start
        actionlint.enable = true;
        alejandra.enable = true;
        deadnix.enable = true;
        keep-sorted.enable = true;
        prettier.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        statix.enable = true;
        stylua.enable = true;
        taplo.enable = true;
        yamlfmt.enable = true;
        # keep-sorted end
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
          # keep-sorted start block=yes newline_separated=yes
          actionlint = {
            includes = [
              ".github/workflows/*.yml"
              ".github/workflows/*.yaml"
            ];
          };

          alejandra = {priority = 3;};

          deadnix = {priority = 1;};

          keep-sorted = {
            includes = ["*"];
          };

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

          statix = {priority = 2;};

          taplo = {
            options = ["format"];
            includes = ["*.toml"];
          };

          yamlfmt = {
            includes = ["*.yml" "*.yaml"];
          };
          # keep-sorted end
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
