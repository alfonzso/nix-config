{ config, ... }:
{
  home-manager.users.${config.hostCfg.username}.programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";

    policies = {
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        };
        "vimium-c@gdh1995.cn" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
        };
      };
    };

    profiles.default = {
      id = 0;
      isDefault = true;
      name = "default";
      settings = {
        "browser.bookmarks.restore_default_bookmarks" = false;
        "browser.bookmarks.showMobileBookmarks" = false;
        "browser.download.useDownloadDir" = false;
        "browser.formfill.enable" = false;
        "browser.newtabpage.pinned" = ''[{"url":"https://claude.ai/","label":"Claude"}]'';
        "browser.startup.page" = 3;
        "browser.toolbars.bookmarks.visibility" = "always";
        "browser.translations.neverTranslateLanguages" = "hu";
        "intl.accept_languages" = "en-us";
        "network.dns.disablePrefetch" = true;
        "network.http.speculative-parallel-limit" = 0;
        "network.prefetch-next" = false;
        "privacy.donottrackheader.enabled" = true;
      };
    };
  };
}
