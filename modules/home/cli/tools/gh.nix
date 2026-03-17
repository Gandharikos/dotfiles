{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my.gh;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.gh = {
    enable = mkEnableOption "gh";
  };

  config = mkIf cfg.enable {
    programs.gh = {
      enable = true;
      extensions = with pkgs; [
        github-copilot-cli
        gh-markdown-preview
        gh-dash
        gh-notify
        gh-f
      ];
      settings = {
        aliases = {
          rcl = "repo clone";
          rcr = "repo create";
          rfk = "repo fork --clone --remote";
          rvw = "repo view --web";
          icl = "issue close";
          icr = "issue create";
          il = "issue list";
          ire = "issue reopen";
          iv = "issue view";
          ivw = "issue view --web";
          pco = "pr checkout";
          pck = "pr checks";
          pcl = "pr close";
          pcr = "pr create";
          pd = "pr diff";
          pl = "pr list";
          pm = "pr merge";
          pre = "pr reopen";
          pv = "pr view";
          pvw = "pr view --web";
          pc = "pr checkout";
          cs = "copilot suggest";
          ce = "copilot explain";
        };
        editor = "nvim";
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };
  };
}
