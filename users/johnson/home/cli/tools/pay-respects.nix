{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;

  cfg = config.my.pay-respects;
in
{
  options.my.pay-respects = {
    enable = mkEnableOption "pay-respects";
  };

  config = mkIf cfg.enable {
    programs.pay-respects = {
      # Pay-respects documentation
      # See: https://github.com/iffse/pay-respects
      enable = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      # Edit these directly here as you experiment with pay-respects behavior.
      options = [
        "--alias"
        "fuck"
        "--nocnf"
      ];

      rules = {
        _PR_GENERAL = {
          match_err = [
            {
              pattern = [ "permission denied" ];
              suggest = [
                "#[executable(sudo), !cmd_contains(sudo)]\nsudo {{command}}"
              ];
            }
          ];
        };

        cargo = {
          command = "cargo";
          match_err = [
            {
              pattern = [ "could not find `Cargo.toml`" ];
              suggest = [ "cargo init" ];
            }
          ];
        };

        git = {
          command = "git";
          match_err = [
            {
              pattern = [ "has no upstream branch" ];
              suggest = [ "git push --set-upstream origin $(git branch --show-current)" ];
            }
          ];
        };

        nix = {
          command = "nix";
          match_err = [
            {
              pattern = [ "does not provide attribute" ];
              suggest = [ "nix flake show" ];
            }
          ];
        };
      };
    };
  };
}
