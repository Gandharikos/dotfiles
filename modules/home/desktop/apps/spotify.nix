{
  self,
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
  # inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (pkgs.stdenv) system;
  inherit (config.home) homeDirectory;
  inherit (config.my) name;
  cfg = config.my.desktop.apps.spotify;
in {
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  options.my.desktop.apps.spotify = {
    enable =
      mkEnableOption "Spotify"
      // {
        default = config.my.desktop.enable;
      };
    spotify-player.enable =
      mkEnableOption "Spotify Player TUI"
      // {
        default = config.my.desktop.apps.spotify.enable;
      };
    spicetify.enable =
      mkEnableOption "Spicetify"
      // {
        default = config.my.desktop.apps.spotify.enable;
      };
  };

  config = mkMerge [
    (mkIf cfg.spicetify.enable {
      programs.spicetify = let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${system};
      in {
        enable = true;
        # windowManagerPatch = isLinux;
        enabledCustomApps = with spicePkgs.apps; [
          lyricsPlus
          reddit
          marketplace
          ncsVisualizer
          historyInSidebar
          betterLibrary
        ];
        enabledExtensions = with spicePkgs.extensions; [
          adblock
          fullAppDisplay
          keyboardShortcut
          hidePodcasts
          songStats
          shuffle # shuffle+ (special characters are sanitized out of extension names)
          playlistIcons
          powerBar
        ];
      };
    })
    (mkIf cfg.spotify-player.enable {
      programs.spotify-player = {
        enable = true;
        settings = {
          client_id_command = "cat ${config.sops.secrets.spotify_client_id.path}";
          clinet_port = 8080;
          layout.playback_window_position = "Bottom";
          border_type = "Rounded";
          play_icon = " ";
          pause_icon = " ";
          liked_icon = "󰋑 ";
        };
        actions = [
          {
            action = "ToggleLiked";
            key_sequence = "C-l";
          }
          # {
          #   action = "AddToLibrary";
          #   key_sequence = "C-a";
          # }
          # {
          #   action = "Follow";
          #   key_sequence = "F";
          # }
        ];
        keymaps = [
          {
            command = "NextTrack";
            key_sequence = "o";
          }
          {
            command = "PreviousTrack";
            key_sequence = "n";
          }
          {
            command = "SeekForward";
            key_sequence = "O";
          }
          {
            command = "SeekBackward";
            key_sequence = "N";
          }
          {
            command = "SelectNextOrScrollDown";
            key_sequence = "e";
          }
          {
            command = "SelectPreviousOrScrollUp";
            key_sequence = "i";
          }
          {
            command = "MovePlaylistItemUp";
            key_sequence = "C-i";
          }
          {
            command = "MovePlaylistItemDown";
            key_sequence = "C-e";
          }
        ];
      };

      home.persistence."/persist" = {
        directories = [".cache/spotify-player"];
      };

      sops.secrets = {
        spotify-player = {
          sopsFile = "${self}/secrets/${name}/spotify-player";
          path = "${homeDirectory}/.cache/spotify-player/credentials.json";
          mode = "0644";
          format = "binary";
        };
        spotify_client_id = {};
      };
    })
  ];
}
