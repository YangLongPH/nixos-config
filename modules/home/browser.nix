{ inputs, pkgs, ... }:
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = false;
  };

  home.packages = with pkgs; [
    brave
    (google-chrome.override { commandLineArgs = "--password-store=basic"; })
  ];
}
