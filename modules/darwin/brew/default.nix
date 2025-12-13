{
  inputs,
  config,
  pkgs,
  ...
}: {
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
        rev = "7405569ec206c9d3ad424d49cb0f5445a4cf6963";
        hash = "sha256-F2cfcsLWtQi4Q2ZeaOIvDRd3pi1MAusAisfcblAtuJ8=";
      };
      "homebrew/homebrew-cask" = pkgs.fetchFromGitHub {
        owner = "homebrew";
        repo = "homebrew-cask";
        rev = "e02e22de85f1a2b62812353d0b8c48d7f83cddbb";
        hash = "sha256-qRP1pCBnIb57puRTSeS9+xci4bXFDU1MmBuEQ1gaYpE=";
      };
      "nikitabobko/homebrew-tap" = pkgs.fetchFromGitHub {
        owner = "nikitabobko";
        repo = "homebrew-tap";
        rev = "80dfd269edca8bc2ec5d83dbd332863cf684f753";
        hash = "sha256-OQJ6Wx6Pi61uu46I7xaHpeiTavDQp1ZLVbHJGR1NL20=";
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
      "reattach-to-user-namespace" # need by tmux
      "wget"
      "curl"
      "aria2" # download tool

      # https://github.com/rgcr/m-cli
      "m-cli" #  Swiss Army Knife for macOS

      # commands like `gsed` `gtar` are required by some tools
      "gnu-sed"
      "gnu-tar"
      # misc that nix do not have cache for.
      "git-trim"
      "terraform"
      "terraformer"
      # for development
      "qt@5"
      "openssh"
    ];

    # `brew install --cask`
    casks = [
      "squirrel-app" # input method for Chinese, rime-squirrel
      "zen" # web browser
      # "visual-studio-code" # editor
      # "telegram" # IM
      "rustdesk" # remote desktop client
      # "iina" # video player
      "raycast" # search
      "stats" # beautiful system monitor
      "eudic" # dictionary
      # "spotify" # music
      "1password" # password manager
      "1password-cli"
      "vlc" # video player
      "obs" # stream / recoding software
      "ghostty" # terminal
      # "obsidian" # note-taking
      "miniforge" # Miniconda's community-driven distribution
      "tencent-lemon" # clean tool
      "surge" # proxy tool
      "keycastr" # show keystrokes on screen
      # "obs" # stream / recoding software
      # virtualization
      "orbstack"
      # "karabiner-elements" # keyboard remap
      "yubico-authenticator" # for yubikey
      "veracrypt" # disk encryption
      # sing-box
      "sfm"
      "karabiner-elements" # keyboard remap
    ];
  };
}
