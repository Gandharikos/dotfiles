{
  lib,
  pkgs,
  ...
}:
{
  console = {
    enable = lib.mkDefault true;
    earlySetup = true;

    keyMap = "en";
    # Using larger font for better readability in console
    # Available sizes: ter-d18n (18), ter-d24n (24), ter-d28n (28), ter-d32n (32)
    font = "${pkgs.terminus_font}/share/consolefonts/ter-d32n.psf.gz";
  };
}
