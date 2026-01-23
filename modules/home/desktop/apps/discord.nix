{
  inputs,
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.home) homeDirectory;
  cfg = config.my.desktop.apps.discord;
in {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  options.my.desktop.apps.discord = {
    enable =
      mkEnableOption "Discord"
      // {
        default = config.my.desktop.enable;
      };
  };

  config = mkIf cfg.enable {
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
          betterNotesBox.enable = true;
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

    home.persistence."/persist${homeDirectory}" = {
      allowOther = true;
      directories = [
        ".config/Discord"
        ".config/discord"
        ".config/vesktop"
        ".config/vencord"
      ];
    };
  };
}
