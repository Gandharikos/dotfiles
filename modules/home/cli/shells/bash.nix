{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.dot.bash;
in
{
  options.dot.bash = {
    enable = mkEnableOption "bash" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      historyFile = "$HOME/.bash_history";
      historyFileSize = 2000;
      historySize = 1000;
      historyControl = [ "erasedups" ];
      historyIgnore = [
        "ls"
        "exit"
        "kill"
      ];
      shellOptions = [
        "histappend"
        "autocd"
        "globstar"
        "checkwinsize"
        "cdspell"
        "dirspell"
        "expand_aliases"
        "dotglob"
        "gnu_errfmt"
        "histreedit"
        "nocasematch"
      ];
      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
      };
    };
  };
}
