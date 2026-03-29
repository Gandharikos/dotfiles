_: _final: prev: {
  vimPlugins = prev.vimPlugins.extend (
    _f: p: {
      tokyonight-nvim = p.tokyonight-nvim.overrideAttrs (_old: {
        version = "4.14.1-unstable-2026-03-24";
        src = prev.fetchFromGitHub {
          owner = "folke";
          repo = "tokyonight.nvim";
          rev = "cdc07ac78467a233fd62c493de29a17e0cf2b2b6";
          hash = "sha256-a9iRWue7DB7s/wNdxqqB51Jya5P9X6sDftqhdmKggU0=";
        };
      });
    }
  );
}
