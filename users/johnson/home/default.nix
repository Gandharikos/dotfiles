{ config, ... }:
{
  imports = [
    ./cli.nix
    ./dev.nix
    ./gui.nix
    ./mail.nix
    ./theme
  ];

  my.security.gpg = {
    key = "776C7FC245E58F55";
    publicKeysPath = "${config.my.secretsCore}/gpg-keys.pub";
    encrytionKey = "6E714D9B24EF3018DB51E7892BE66A4F9E095541";
    signatureKey = "EC571D2B91912D528A9F3B00639746C15BE596AF";
  };
}
