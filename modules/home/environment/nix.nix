_: {
  # Enable nix command and flakes for user-level nix commands (like nh)
  nix = {
    package = null; # Use system nix
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
