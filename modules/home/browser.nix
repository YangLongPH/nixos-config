{ inputs, pkgs, lib, ... }:
let
  # Open-source extensions cloned to ~/work/github, loaded as unpacked via proxy files.
  # Run build-zen-extensions once (and after git pull) to build and register them.
  # Proxy file format: file named <ext-id> in extensions/ whose content is the built dir path.
  unpackedExtensions = {
    "addon@darkreader.org" =
      "/home/yanglong/work/github/darkreader/build/release/firefox";
    "adguardadblockerdev@adguard.com" =
      "/home/yanglong/work/github/AdguardBrowserExtension/build/dev/firefox-amo";
    "devbuild@adblockplus.org" =
      "/home/yanglong/work/github/adblockpluschrome/devenv.firefox";
  };

  extensionRepos = {
    "darkreader" = "https://github.com/darkreader/darkreader";
    "AdguardBrowserExtension" = "https://github.com/AdguardTeam/AdguardBrowserExtension";
    "adblockpluschrome" = "https://github.com/adblockplus/adblockpluschrome";
  };

  cloneScript = pkgs.writeShellScript "zen-clone-extension-repos" ''
    export PATH="$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"
    GITHUB_DIR="$HOME/work/github"
    mkdir -p "$GITHUB_DIR"

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: url: ''
      if [ ! -d "$GITHUB_DIR/${name}" ]; then
        echo "Cloning ${name}..."
        GIT_CONFIG_GLOBAL=/dev/null ${pkgs.git}/bin/git clone "${url}" "$GITHUB_DIR/${name}"
      fi
    '') extensionRepos)}

    needs_build=0
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (_id: path: ''
      [ -f "${path}/manifest.json" ] || needs_build=1
    '') unpackedExtensions)}

    if [ "$needs_build" = "1" ]; then
      echo "Building Zen extensions..."
      build-zen-extensions
    fi
  '';
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = false;
  };

  # Clones extension repos after login (not during activation) so it never blocks nixos-rebuild.
  # GIT_CONFIG_GLOBAL=/dev/null bypasses the https->SSH insteadOf rewrite in ~/.gitconfig.
  # No WantedBy — triggered from Hyprland exec-once instead so home-manager never starts it.
  systemd.user.services.zen-extension-repos = {
    Unit = {
      Description = "Clone Zen browser extension repos";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${cloneScript}";
    };
  };

  # Detect the default Zen profile dynamically from profiles.ini so this works
  # across machines (profile IDs are randomly generated per installation).
  # Writes user.js (unsigned extension support) and proxy files for unpacked extensions.
  home.activation.zenUnpackedExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ZEN_DIR="$HOME/.config/zen"
    PROFILES_INI="$ZEN_DIR/profiles.ini"

    if [ -f "$PROFILES_INI" ]; then
      PROFILE_NAME=$(grep -B5 "^Default=1" "$PROFILES_INI" | grep "^Path=" | tail -1 | sed 's/^Path=//')
      IS_RELATIVE=$(grep -B5 "^Default=1" "$PROFILES_INI" | grep "^IsRelative=" | tail -1 | sed 's/^IsRelative=//')
      if [ "$IS_RELATIVE" = "1" ]; then
        PROFILE_DIR="$ZEN_DIR/$PROFILE_NAME"
      else
        PROFILE_DIR="$PROFILE_NAME"
      fi

      if [ -n "$PROFILE_DIR" ]; then
        EXT_DIR="$PROFILE_DIR/extensions"
        mkdir -p "$EXT_DIR"

        printf '%s\n' 'user_pref("xpinstall.signatures.required", false);' > "$PROFILE_DIR/user.js"
        printf '%s\n' 'user_pref("extensions.autoDisableScopes", 0);' >> "$PROFILE_DIR/user.js"

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (id: path: ''
          if [ -f "${path}/manifest.json" ]; then
            printf '%s' "${path}" > "$EXT_DIR/${id}"
          fi
        '') unpackedExtensions)}
      fi
    fi
  '';

  home.packages = with pkgs; [
    (brave.override { commandLineArgs = "--password-store=basic"; })
    (google-chrome.override { commandLineArgs = "--password-store=basic"; })
  ];
}
