{
  inputs,
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.discord;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  options.my.gui.apps.discord = {
    enable = mkEnableOption "Discord" // {
      default = osConfig.dot.gui.enable;
    };
  };

  config = mkIf enable {
    programs.nixcord = {
      enable = true;
      discord.enable = false;
      vesktop.enable = true;
      config = {
        useQuickCss = true;
        plugins = {
          alwaysAnimate.enable = true;
          alwaysExpandRoles.enable = true;
          betterGifAltText.enable = true;
          betterGifPicker.enable = true;
          betterRoleDot.enable = true;
          betterUploadButton.enable = true;
          betterSessions.enable = true;
          betterSettings.enable = true;
          biggerStreamPreview.enable = true;
          copyEmojiMarkdown.enable = true;
          dearrow.enable = true;
          decor.enable = true;
          fakeNitro.enable = true;
          fixSpotifyEmbeds.enable = true;
          fixYoutubeEmbeds.enable = true;
          openInApp.enable = true;
          translate = {
            enable = true;
            autoTranslate = true;
          };
          typingIndicator.enable = true;
          youtubeAdblock.enable = true;
          # hideAttachments.enable = true;
          readAllNotificationsButton.enable = true;
          # clearUrLs.enable = true;
          friendsSince.enable = true;
        };
      };
    };
  };
}
