{ inputs, pkgs, lib, ... }:
let
  zenProfile = ".config/zen/3f0perh2.Default Profile";

  # Open-source extensions cloned to ~/work/github, loaded as unpacked via proxy files.
  # Run scripts/build-zen-extensions.sh once (and after git pull) to build and register them.
  # Proxy file format: file named <ext-id> in extensions/ whose content is the built dir path.
  unpackedExtensions = {
    "addon@darkreader.org" =
      "/home/yanglong/work/github/darkreader/build/release/firefox";
    "adguardadblockerdev@adguard.com" =
      "/home/yanglong/work/github/AdguardBrowserExtension/build/dev/firefox-amo";
    "devbuild@adblockplus.org" =
      "/home/yanglong/work/github/adblockpluschrome/devenv.firefox";
  };
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = false;
  };

  # Allow unsigned/unpacked extensions in the existing profile.
  # Google Mail Checker and Save to Pinterest: install manually via about:addons.
  home.file."${zenProfile}/user.js".text = ''
    user_pref("xpinstall.signatures.required", false);
    user_pref("extensions.autoDisableScopes", 0);
  '';

  # Create/refresh proxy files after each nixos-rebuild (only if build exists).
  home.activation.zenUnpackedExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    EXT_DIR="$HOME/${zenProfile}/extensions"
    mkdir -p "$EXT_DIR"
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (id: path: ''
      if [ -f "${path}/manifest.json" ]; then
        printf '%s' "${path}" > "$EXT_DIR/${id}"
      fi
    '') unpackedExtensions)}
  '';

  home.packages = with pkgs; [
    brave
    (google-chrome.override { commandLineArgs = "--password-store=basic"; })
  ];
}
