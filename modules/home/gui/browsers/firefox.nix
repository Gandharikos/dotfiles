{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.apps.firefox;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.firefox = {
    enable = mkEnableOption "firefox" // {
      default = config.my.gui.browser.default == "firefox";
    };
  };

  config = mkIf enable {
    programs.firefox = {
      enable = true;
      policies = {
        # NOTE: Can't be enabled outside US and some other countries
        # AutofillAddressEnabled = true;
        # AutofillCreditCardEnabled = true;
        DisableAppUpdate = true;
        DisableFirefoxScreenshots = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableSetDesktopBackground = true;
        DisableTelemetry = true;
        DisplayBookmarksToolbar = "never";
        DisplayMenuBar = "never";
        DontCheckDefaultBrowser = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        FirefoxHome = {
          Highlights = false;
          Locked = true;
          Pocket = false;
          Search = true;
          Snippets = false;
          SponsoredPocket = false;
          SponsoredStories = false;
          SponsoredTopSites = false;
          Stories = false;
          TopSites = false;
        };
        FirefoxSuggest = {
          SponsoredSuggestions = false;
          Locked = true;
        };
        HardwareAcceleration = true;
        Homepage = {
          Locked = true;
          StartPage = "previous-session";
        };
        NoDefaultBookmarks = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        ShowHomeButton = true;
        UserMessaging = {
          ExtensionRecommendations = false;
          FeatureRecommendations = false;
          FirefoxLabs = false;
          Locked = true;
          MoreFromMozilla = false;
          SkipOnboarding = true;
          UrlbarInterventions = false;
          WhatsNew = false;
        };
      };

      profiles.default = {
        isDefault = true;

        userContent =
          # css
          ''
            /* dark background for default tabs */
            @-moz-document url("about:home"), url("about:blank"), url("about:newtab") {
              body {
                background-color: #24273a !important;
              }
            }
          '';

        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.aboutwelcome.enabled" = false;
          "browser.tabs.unloadOnLowMemory" = true;
          "browser.urlbar.suggest.calculator" = true;
          "browser.urlbar.trimHttps" = true;
          "browser.urlbar.unitConversion.enabled" = true;
          "browser.urlbar.untrimOnUserInteraction.featureGate" = true;
          "cookiebanners.service.mode" = 1;
          "cookiebanners.service.mode.privateBrowsing" = 1;
          "extensions.getAddons.showPane" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "findbar.highlightAll" = true;

          # smoother scrolling
          "mousewheel.min_line_scroll_amount" = 25;
          "general.smoothScroll.mouseWheel.durationMinMS" = 400;
          "general.smoothScroll.mouseWheel.durationMaxMS" = 500;

          "font.name.monospace.x-western" = "DejaVuSansM Nerd Font Mono";
          "font.name.sans-serif.x-western" = "DejaVuSansM Nerd Font";
          "font.name.serif.x-western" = "DejaVuSansM Nerd Font";

          # diable fullscreen notification
          "full-screen-api.transition-duration.enter" = "0 0";
          "full-screen-api.transition-duration.leave" = "0 0";
          "full-screen-api.warning.delay" = -1;
          "full-screen-api.warning.timeout" = 0;

          "media.videocontrols.picture-in-picture.enabled" = true;
          "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
          "permissions.default.desktop-notification" = 2;
          "privacy.donottrackheader.enabled" = true;
          "security.insecure_connection_text.enabled" = true;
          "security.insecure_connection_text.pbmode.enabled" = true;
          "security.osclientcerts.autoload" = true;

          # translation
          # "browser.translations.alwaysTranslateLanguages" = "bs,de,lv,sr,uk";
          # "browser.translations.neverTranslateLanguages" = "en,ru";
        };

        search = {
          force = true;
          default = "google";
          engines = {
            "google".metaData.alias = "g";

            "ddg".metaData.alias = "dg";

            "GitHub" = {
              definedAliases = [ "gh" ];
              urls = [
                {
                  template = "https://github.com/search?q={searchTerms}&type=code";
                }
              ];
              icon = "https://github.githubassets.com/favicons/favicon-dark.png";
              updateInterval = 7 * 24 * 60 * 60 * 1000; # every week
            };

            "youtube" = {
              definedAliases = [ "yt" ];
              urls = [
                {
                  template = "https://www.youtube.com/results?search_query={searchTerms}";
                }
              ];
              icon = "https://www.youtube.com/s/desktop/6b6081dd/img/favicon_32x32.png";
              updateInterval = 7 * 24 * 60 * 60 * 1000; # every week
            };

            "ArtifactHUB" = {
              definedAliases = [ "ah" ];
              urls = [
                {
                  template = "https://artifacthub.io/packages/search?sort=relevance&page=1&ts_query_web={searchTerms}";
                }
              ];
            };

            "My NixOS" = {
              definedAliases = [ "mn" ];
              urls = [ { template = "https://mynixos.com/search?q={searchTerms}"; } ];
              icon = "https://mynixos.com/favicon.ico";
              updateInterval = 7 * 24 * 60 * 60 * 1000; # every week
            };

            "NixOS Packages" = {
              definedAliases = [ "np" ];
              urls = [
                {
                  template = "https://search.nixos.org/packages?query={searchTerms}";
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            };

            "NixOS Options" = {
              definedAliases = [ "no" ];
              urls = [
                {
                  template = "https://search.nixos.org/options?query={searchTerms}";
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            };

            "home-manager Options" = {
              definedAliases = [ "hmo" ];
              urls = [
                {
                  template = "https://home-manager-options.extranix.com/?query={searchTerms}";
                }
              ];
              icon = "https://home-manager-options.extranix.com/images/favicon.png";
            };

            "NixOS Wiki" = {
              definedAliases = [ "nw" ];
              urls = [
                {
                  template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            };

            "GitHub lang:nix" = {
              definedAliases = [ "ghln" ];
              urls = [
                {
                  template = "https://github.com/search?q=lang:nix {searchTerms}&type=code";
                }
              ];
              icon = "https://github.githubassets.com/favicons/favicon-dark.png";
              updateInterval = 7 * 24 * 60 * 60 * 1000; # every week
            };

            "GitHub nixpkgs" = {
              definedAliases = [ "ghnp" ];
              urls = [
                {
                  template = "https://github.com/search?q=repo%3ANixOS%2Fnixpkgs {searchTerms}&type=code";
                }
              ];
              icon = "https://github.githubassets.com/favicons/favicon-dark.png";
              updateInterval = 7 * 24 * 60 * 60 * 1000; # every week
            };

            "Freedium.cfd" = {
              definedAliases = [ "fd" ];
              urls = [ { template = "https://freedium.cfd/{searchTerms}"; } ];
              icon = "https://miro.medium.com/v2/5d8de952517e8160e40ef9841c781cdc14a5db313057fa3c3de41c6f5b494b19";
              updateInterval = 7 * 24 * 60 * 60 * 1000; # every week
            };

            "ProtonDB" = {
              definedAliases = [ "pd" ];
              urls = [ { template = "https://protondb.com/search?q={searchTerms}"; } ];
              icon = "https://protondb.com/sites/protondb/images/favicon.ico";
              updateInterval = 7 * 24 * 60 * 60 * 1000; # every week
            };

            "HowLongToBeat" = {
              definedAliases = [ "hltb" ];
              urls = [ { template = "https://howlongtobeat.com/?q={searchTerms}"; } ];
              icon = "https://howlongtobeat.com/img/icons/favicon-32x32.png";
              updateInterval = 7 * 24 * 60 * 60 * 1000; # every week
            };
          };
        };
      };
    };
  };
}
