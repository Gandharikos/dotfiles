{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.nixporn) palette;

  enable = config.nixporn.colorscheme == "tokyonight" && config.my.broot.enable;

  extColors = with palette; {
    asm = orange;
    bash = green;
    c = blue;
    cc = blue;
    clj = green1;
    cljs = green1;
    cpp = blue;
    cs = green;
    css = magenta;
    dart = cyan;
    diff = git_change;
    dockerfile = blue7;
    eex = purple;
    ex = purple;
    exs = purple;
    go = cyan;
    h = blue;
    heex = purple;
    hpp = blue;
    hs = magenta;
    html = orange;
    java = orange;
    jl = purple;
    js = yellow;
    json = yellow;
    jsx = yellow;
    kt = purple;
    kts = purple;
    lua = blue;
    m = blue1;
    md = blue;
    mdx = blue;
    ml = green;
    mli = green;
    nim = yellow;
    nix = blue;
    php = magenta;
    pl = cyan;
    pm = cyan;
    proto = fg_dark;
    py = blue;
    r = blue1;
    rb = red;
    rs = orange;
    scala = red;
    scss = magenta2;
    sh = green;
    sql = orange;
    svelte = orange;
    swift = orange;
    toml = orange;
    ts = blue;
    tsx = blue;
    vim = green;
    vue = green1;
    xml = blue1;
    yaml = red;
    yml = red;
    zig = orange;
    zsh = green;
  };
in
{
  config = mkIf enable {
    programs.broot.settings.ext-colors = extColors;
  };
}
