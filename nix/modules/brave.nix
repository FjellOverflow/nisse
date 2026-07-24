{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ brave ];

  xdg.mime.defaultApplications = {
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
    "text/html" = "brave-browser.desktop";
    "application/xhtml+xml" = "brave-browser.desktop";
  };

  environment.etc."brave/policies/managed/policy.json".text = builtins.toJSON {
    # Brave features
    BraveRewardsDisabled = true;
    BraveWalletDisabled = true;
    BraveVPNDisabled = true;
    BraveAIChatEnabled = false;
    BraveP3AEnabled = false;
    BraveStatsPingEnabled = false;
    BraveWebDiscoveryEnabled = false;
    BraveNewsDisabled = true;
    BraveTalkDisabled = true;
    BraveSpeedreaderEnabled = false;
    BraveWaybackMachineEnabled = false;
    BravePlaylistEnabled = false;
    SyncDisabled = true;
    # Chromium
    PromotionalTabsEnabled = false;
    MetricsReportingEnabled = false;
    BackgroundModeEnabled = false;
    PasswordManagerEnabled = false;
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    TranslateEnabled = false;
    SpellCheckServiceEnabled = false;
    SearchSuggestEnabled = false;
    NetworkPredictionOptions = 2;
    DefaultBrowserSettingEnabled = false;
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "DuckDuckGo";
    DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
    UserFeedbackAllowed = false;
    SafeBrowsingExtendedReportingEnabled = false;
    ImportBrowserSettings = false;
    DnsOverHttpsMode = "secure";
    DnsOverHttpsTemplates = "https://dns.adguard-dns.com/dns-query";
    # Extensions
    ExtensionInstallForcelist = [
      # Bitwarden
      "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx"
      # Google Translate
      "aapbdbdomjkkjkaonfhkkikfgjllcleb;https://clients2.google.com/service/update2/crx"
    ];
  };
}
