{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    rclone
    (writeShellScriptBin "rclone-login" ''
      CLIENT_ID="1091648753631-eruhuthjhlen410kf4ejl800p4vjq949.apps.googleusercontent.com"
      read -rsp "Enter Google OAuth client secret: " CLIENT_SECRET
      echo
      rclone config delete gdrive 2>/dev/null
      rclone config create gdrive drive client_id="$CLIENT_ID" client_secret="$CLIENT_SECRET" scope=drive
      rclone config reconnect gdrive:
      echo "Done! Google Drive is ready."
    '')
  ];

  home.activation.rcloneSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.util-linux}/bin/umount -l $HOME/GoogleDrive 2>/dev/null || true
    $DRY_RUN_CMD mkdir -p $HOME/GoogleDrive
  '';

  # Mount Google Drive at ~/GoogleDrive
  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "Google Drive (rclone mount)";
      After = [ "network-online.target" ];
      Wants = [ "rclone-wallpaper-sync.service" ];
    };
    Service = {
      Type = "notify";
      ExecStart = "${pkgs.rclone}/bin/rclone mount gdrive: %h/GoogleDrive --vfs-cache-mode writes --vfs-cache-max-size 512M";
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u %h/GoogleDrive";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Sync gdrive:wallpapers → ~/Pictures/wallpapers (daily + on boot)
  systemd.user.services.rclone-wallpaper-sync = {
    Unit = {
      Description = "Sync wallpapers from Google Drive";
      After = [ "network-online.target" "rclone-gdrive.service" ];
      Requires = [ "rclone-gdrive.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.rclone}/bin/rclone sync gdrive:MacBookBG %h/Pictures/wallpapers --create-empty-src-dirs";
      Restart = "on-failure";
      RestartSec = "60s";
    };
  };

  systemd.user.timers.rclone-wallpaper-sync = {
    Unit.Description = "Daily wallpaper sync from Google Drive";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1d";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
