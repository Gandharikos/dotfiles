_: _final: prev: {
  kulala-core = prev.kulala-core.overrideAttrs (old: {
    node_modules = old.node_modules.overrideAttrs (_: {
      outputHash = "sha256-XQlBawD3vt8pVc7Gy9XeiGie89HWbljNJt7kUEDaDKk=";
    });
  });

  vimPlugins = prev.vimPlugins.extend (
    _f: _p: {
      # nvim-tree-preview = pkgs.vimUtils.buildVimPlugin {
      #   name = "nvim-tree-preview";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "b0o";
      #     repo = "nvim-tree-preview.lua";
      #     rev = "e763de51dca15d65ce4a0b9eca716136ac51b55c";
      #     hash = "sha256-7XPYnset01YEtwPUEcS+cXZQwf8h9cARKlgwwCUT3YY=";
      #   };
      # };

      venv-selector-nvim = prev.vimUtils.buildVimPlugin {
        pname = "venv-selector.nvim";
        version = "2025-10-18";
        src = prev.fetchFromGitHub {
          owner = "linux-cultist";
          repo = "venv-selector.nvim";
          rev = "7fff64b5b1455207b9a9fd2ae8697cf9ac0b2a2d";
          hash = "sha256-m165YyY8VX0YQ5v6vxDJp4avDRrxByZQY+uMNkubggo=";
        };
      };

      cmp-r = prev.vimUtils.buildVimPlugin {
        pname = "cmp-r";
        version = "unstable-2024-11-11";

        src = prev.fetchFromGitHub {
          owner = "R-nvim";
          repo = "cmp-r";
          rev = "3b03cba13976b3ec5fcf7736bde02dacf89254b1";
          hash = "sha256-mOJTakVvrVapsCH7R6Sl1k/5z1R6P3gZVftBb6/WkC8=";
        };
      };

      R-nvim = prev.vimUtils.buildVimPlugin {
        pname = "R.nvim";
        version = "0.1.0";

        src = prev.fetchFromGitHub {
          owner = "R-nvim";
          repo = "R.nvim";
          rev = "fef990378e4b5157f23314dca4136bc0079cc2c4";
          hash = "sha256-KgvK2tR6C97Z1WEUbVNHzAe6QKUg0T5FLB9HwO3eay4=";
        };

        # Skip nvimcom build - it tries to write to read-only Nix store
        postPatch = ''
          rm -rf nvimcom
        '';
      };
    }
  );
}
