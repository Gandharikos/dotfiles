{
  lib,
  config,
  themeNamespace ? "dot",
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.dot) scanPaths capitalize;
  namespace = themeNamespace;
  cfg = config.${namespace}.theme.tokyonight;
in
{
  imports = scanPaths ./.;

  config = mkIf cfg.enable {
    ${namespace}.theme.colorscheme = {
      slug = "tokyonight_${cfg.style}";
      name = "Tokyo Night ${capitalize cfg.style}";
      description = "A dark, high-contrast color scheme copy from tokyonight.nvim by folke";
      author = "folke";
    };
  };
}
