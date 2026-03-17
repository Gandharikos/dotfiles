{
  config,
  lib,
  ...
}:
let
  cfg = config.my.ripgrep;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.ripgrep = {
    enable = mkEnableOption "ripgrep";
  };

  config = mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
      arguments = [
        # Don't let ripgrep vomit really long lines to my terminal, and show a preview.
        "--max-columns=150"
        "--max-columns-preview"

        # Add my 'web' type.
        "--type-add"
        "web:*.{html,css,js}*"

        # Search hidden files / directories (e.g. dotfiles) by default
        "--hidden"

        # Using glob patterns to include/exclude files or folders
        "--glob=!.git/*"

        # or
        "--glob"
        "!.git/*"

        # Set the colors.
        "--colors=line:none"
        "--colors=line:style:bold"

        # Because who cares about case!?
        "--smart-case"
      ];
    };
  };
}
