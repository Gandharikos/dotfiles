_: _final: prev: {
  vimPlugins = prev.vimPlugins.extend (
    _f: _p: {
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
