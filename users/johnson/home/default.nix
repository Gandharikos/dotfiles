{ lib, osConfig, ... }:
let
  isMinimal = osConfig ? dot && osConfig.dot.profiles.minimal.enable or false;
in
{
  imports = lib.dot.scanPaths ./.;

  my = {
    # keep-sorted start block=yes newline_separated=yes
    _1password-cli = {
      enable = !isMinimal;
      enableSshSocket = !isMinimal;
    };

    agy.enable = !isMinimal;

    atuin = {
      enable = true;
      autoLogin = !isMinimal;
    };

    bash.enable = true;

    bat.enable = true;

    broot.enable = !isMinimal;

    btop.enable = true;

    carapace.enable = true;

    claude-code.enable = !isMinimal;

    codex.enable = !isMinimal;

    direnv = {
      enable = true;
      silent = true;
    };

    eza.enable = true;

    fastfetch = {
      enable = true;
      startOnLogin = !isMinimal;
    };

    fd.enable = true;

    fzf.enable = true;

    gh.enable = !isMinimal;

    git.enable = true;

    glow.enable = !isMinimal;

    gui.apps.anki.enable = !isMinimal;

    gui.apps.keyguard.enable = !isMinimal;

    jjui.enable = !isMinimal;

    jujutsu.enable = !isMinimal;

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

    lazygit.enable = !isMinimal;

    mail.enable = !isMinimal;

    mcp.enable = !isMinimal;

    mux = {
      default = if isMinimal then null else "tmux";
      autoStart = !isMinimal;
    };

    navi.enable = !isMinimal;

    neovim = {
      enable = true;
      distro = if isMinimal then null else "lazyvim";
    };

    nix-index.enable = !isMinimal;

    nix-search-tv.enable = !isMinimal;

    nix-your-shell.enable = !isMinimal;

    numbat.enable = !isMinimal;

    opencode.enable = !isMinimal;

    pay-respects.enable = !isMinimal;

    pet.enable = !isMinimal;

    polymarket.enable = !isMinimal;

    ripgrep.enable = true;

    starship.enable = true;

    tealdeer.enable = !isMinimal;

    topgrade.enable = !isMinimal;

    typst.enable = !isMinimal;

    wakatime.enable = !isMinimal;

    yazi.enable = !isMinimal;

    zellij.enable = !isMinimal;

    zk.enable = !isMinimal;

    zoxide.enable = true;
    # keep-sorted end
  };
}
