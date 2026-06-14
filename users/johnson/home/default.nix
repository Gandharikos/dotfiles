{ lib, ... }:
{
  imports = lib.dot.scanPaths ./.;

  my = {
    # keep-sorted start block=yes newline_separated=yes
    _1password-cli = {
      enable = true;
      enableSshSocket = true;
    };

    agy.enable = true;

    atuin = {
      enable = true;
      autoLogin = true;
    };

    bash.enable = true;

    bat.enable = true;

    broot.enable = true;

    btop.enable = true;

    carapace.enable = true;

    claude-code.enable = true;

    codex.enable = true;

    direnv = {
      enable = true;
      silent = true;
    };

    eza.enable = true;

    fastfetch = {
      enable = true;
      startOnLogin = true;
    };

    fd.enable = true;

    fzf.enable = true;

    gh.enable = true;

    git.enable = true;

    glow.enable = true;

    gui.apps.anki.enable = true;

    gui.apps.keyguard.enable = true;

    jjui.enable = true;

    jujutsu.enable = true;

    langs = {
      cc = {
        enable = true;
        xdg.enable = true;
      };

      python = {
        enable = true;
        xdg.enable = true;
      };

      rust = {
        enable = true;
        xdg.enable = true;
      };

      # r = {
      #   enable = true;
      #   xdg.enable = true;
      # };
    };

    lazygit.enable = true;

    mcp.enable = true;

    mux = {
      default = "tmux";
      autoStart = true;
    };

    navi.enable = true;

    neovim.enable = true;

    nix-index.enable = true;

    nix-search-tv.enable = true;

    nix-your-shell.enable = true;

    numbat.enable = true;

    opencode.enable = true;

    pay-respects.enable = true;

    pet.enable = true;

    polymarket.enable = true;

    ripgrep.enable = true;

    starship.enable = true;

    tealdeer.enable = true;

    tmux.enable = true;

    topgrade.enable = true;

    typst.enable = true;

    wakatime.enable = true;

    yazi.enable = true;

    zellij.enable = true;

    zk.enable = true;

    zoxide.enable = true;
    # keep-sorted end
  };
}
