{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ./environment.nix
  ];

  # brought in using nix-homebrew to make homebrew apps reproducible
  nix-homebrew = {
    enable = true;

    # I want to force us to only use declarative taps
    mutableTaps = false;

    # we need a user to install packages for
    user = config.my.name;

    # to truly be declarative, we need to specify the exact revision of homebrew-core
    #
    # you can run the following command to get the latest rev and hash of homebrew-core
    # nix-prefetch-github homebrew homebrew-core --nix
    taps = {
      "homebrew/homebrew-core" = pkgs.fetchFromGitHub {
        owner = "homebrew";
        repo = "homebrew-core";
        rev = "eeb33b65f212bc7f07ba13c58e835c09e6876b61";
        hash = "sha256-pMBIZI9zwKrc4QN6mvtBAcqf6v6bGr3rK8eC4l1WoIQ=";
      };
      "homebrew/homebrew-cask" = pkgs.fetchFromGitHub {
        owner = "homebrew";
        repo = "homebrew-cask";
        rev = "c3fe983f089970e2239f5306f6c28e738d2b00f9";
        hash = "sha256-UICh+QJa7tFHXBkJ1KaY8HRS5I5khTFroVGBPe2Ra4Y=";
      };
      "nikitabobko/homebrew-tap" = pkgs.fetchFromGitHub {
        owner = "nikitabobko";
        repo = "homebrew-tap";
        rev = "db2dcd4d2fd7087457b3cc0baf597880ac4e35a0";
        hash = "sha256-FTE1he09SKkm7e4W4wwuhoBSgM3zROlRYcjZiU7Yjsg=";
      };
    };
  };

  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    global.autoUpdate = false;

    onActivation = {
      # autoUpdate = true; # this should be managered by nix-homebrew
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      cleanup = "zap";
    };

    # Applications to install from Mac App Store using mas
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them
    # For details, see https://github.com/mas-cli/mas

    # Notes: mas-cli is too slow to use with nix

    # masApps = {
    #   Xcode = 497799835;
    #   Wechat = 836500024;
    #   QQ = 451108668;
    #   # WeCom = 1189898970; # Wechat for Work
    #   TecentMeeting = 1484048379;
    #   "Jolt of Caffeine" = 1437130425;
    # };

    # if we don't do this nix-darwin may attempt to remove our taps
    # even when they are managed by nix-homebrew
    taps = builtins.attrNames config.nix-homebrew.taps;

    # `brew install`
    brews = [
      # keep-sorted start

      "aria2" # download tool
      "curl"
      # misc that nix do not have cache for.
      "git-trim"
      # commands like `gsed` `gtar` are required by some tools
      "gnu-sed"
      "gnu-tar"
      # https://github.com/rgcr/m-cli
      "m-cli" #  Swiss Army Knife for macOS
      # deep clearn and optimize your mac
      "mole"
      "openssh"
      # for development
      "qt@5"
      "reattach-to-user-namespace" # need by tmux
      "tailscale"
      "terraform"
      "terraformer"
      "wget"
      # keep-sorted end
    ];

    # `brew install --cask`
    casks = [
      # keep-sorted start
      # "spotify" # music
      "1password" # password manager
      "1password-cli"
      # "stats" # beautiful system monitor
      "eudic" # dictionary
      "ghostty" # terminal
      "granola"
      "keycastr" # show keystrokes on screen
      "linear-linear"
      "loom"
      "macfuse" # required by veracrypt
      "obs" # stream / recoding software
      # "obs" # stream / recoding software
      # virtualization
      "orbstack"
      # "iina" # video player
      "raycast" # search
      # "visual-studio-code" # editor
      # "telegram" # IM
      "rustdesk" # remote desktop client
      # sing-box
      "sfm"
      "slack"
      "squirrel-app" # input method for Chinese, rime-squirrel
      # "obsidian" # note-taking
      # "miniforge" # Miniconda's community-driven distribution
      # "tencent-lemon" # clean tool
      "surge" # proxy tool
      "veracrypt" # disk encryption
      "vlc" # video player
      # "karabiner-elements" # keyboard remap
      "yubico-authenticator" # for yubikey
      "zen" # web browser
      # keep-sorted end
    ];
  };
}
