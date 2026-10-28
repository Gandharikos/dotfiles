_: _final: prev: {
  vimPlugins = prev.vimPlugins.extend (
    _f: p: {
      # Pin smart-splits.nvim to v2: v3.0.0 removed built-in multiplexer
      # backends and smart-splits.tmux into separate repositories.
      smart-splits-nvim = p.smart-splits-nvim.overrideAttrs (_old: {
        version = "2.1.0-unstable-2026-09-07";
        src = prev.fetchFromGitHub {
          owner = "smart-splits-nvim";
          repo = "smart-splits.nvim";
          rev = "ec76708f1617ef9e2ac353357fe52d2c997a0f06";
          hash = "sha256-wTNNFmVARLSbhYvr7dkPc+9jJBLEeRah0JB3j4W/7uM=";
        };
      });

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
