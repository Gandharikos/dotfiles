_: _final: prev: {
  vimPlugins = prev.vimPlugins.extend (
    _f: p: {
      smart-splits-nvim = p.smart-splits-nvim.overrideAttrs (_old: {
        version = "3.0.0";
        src = prev.fetchFromGitHub {
          owner = "smart-splits-nvim";
          repo = "smart-splits.nvim";
          rev = "v3.0.0";
          hash = "sha256-IWkFxNGmxwHx9KFg9z9EnWhy3yp+kNMXKDmB0Qhxuic=";
        };
      });

      smart-splits-backend-tmux = prev.vimUtils.buildVimPlugin {
        pname = "smart-splits-backend-tmux";
        version = "unstable-2026-11-02";
        src = prev.fetchFromGitHub {
          owner = "smart-splits-nvim";
          repo = "backend-tmux";
          rev = "9e9e6aa9b3eb7a8d3896a993611622ac97abff52";
          hash = "sha256-RcJdM6wFHZOEOK+cXVIT10anktqGgIilPmojFpdY+4g=";
        };
      };

      smart-splits-backend-zellij-lua = prev.vimUtils.buildVimPlugin {
        pname = "smart-splits-backend-zellij-lua";
        version = "unstable-2026-11-02";
        src = prev.fetchFromGitHub {
          owner = "smart-splits-nvim";
          repo = "backend-zellij-lua";
          rev = "4e3e588795efb95548dd2ebeaf385a7823821ceb";
          hash = "sha256-QAKX3jHYd2xHjhs8uf44OB04Q+Gl+wXVZOqS09IcRSk=";
        };
      };

      smart-splits-backend-kitty = prev.vimUtils.buildVimPlugin {
        pname = "smart-splits-backend-kitty";
        version = "unstable-2026-11-02";
        src = prev.fetchFromGitHub {
          owner = "smart-splits-nvim";
          repo = "backend-kitty";
          rev = "c8dddf4cea5ce84f2d3d5310acb40565845f19b3";
          hash = "sha256-Xxkji+1yNbYJeBhasPuiMQY5Ba1yR3fPbGPoq/rPeFs=";
        };
      };

      smart-splits-backend-wezterm = prev.vimUtils.buildVimPlugin {
        pname = "smart-splits-backend-wezterm";
        version = "unstable-2026-11-02";
        src = prev.fetchFromGitHub {
          owner = "smart-splits-nvim";
          repo = "backend-wezterm";
          rev = "ae840db696791f638c190c3e0534d2ddfcd5e6a7";
          hash = "sha256-9kDZAoYqQMtSGAE9w70UtkW/DLUmmwVAwCxDxk8om1E=";
        };
      };

      smart-splits-backend-herdr = prev.vimUtils.buildVimPlugin {
        pname = "smart-splits-backend-herdr";
        version = "unstable-2026-10-19";
        src = prev.fetchFromGitHub {
          owner = "adriankarlen";
          repo = "smart-splits-backend-herdr";
          rev = "da1e50ae7bec7a7c2781aaf5a531eff350bdab20";
          hash = "sha256-dLWDAWvWvLT4pZepKj4f38pQGoQjo9UpQkCiAUeBkdU=";
        };
      };

      smart-splits-backend-rex = prev.vimUtils.buildVimPlugin {
        pname = "smart-splits-backend-rex";
        version = "unstable-2026-11-07";
        src = prev.fetchFromGitHub {
          owner = "Gandharikos";
          repo = "smart-splits-backend-rex";
          rev = "9a405d25391ac55cf1ea4a27591580c0e13135dd";
          hash = "sha256-LXPiWRj6qb6MUFQ3qZA6DqlXaCBfdUzbnjlmgHkcuDg=";
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
