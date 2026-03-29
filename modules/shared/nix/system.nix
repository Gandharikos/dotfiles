{
  config,
  _class,
  ...
}:
{
  # This value determines the NixOS and Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new NixOS and Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update NixOS and Home Manager without changing this value.
  # If you want to update your system, both NixOS and Home Manager. see below.
  # This should be change to the version of the NixOS and Home-manager release
  # that the configuration was generated with
  # https://nixos.org/manual/nixos/unstable/release-notes.html
  system.stateVersion = if (_class == "nixos") then config.my.stateVersion else 6;
}
