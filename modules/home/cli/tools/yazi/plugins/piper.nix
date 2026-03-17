{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) piper; };
    settings.plugin.prepend_previewers = [
      {
        name = "*.md";
        run = "piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark \"$1\"";
      }
    ];
  };
}
