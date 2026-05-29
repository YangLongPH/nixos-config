{ pkgs, ... }:
{
  programs.zsh.initExtra = ''
    watson() {
      if [[ "$1" == "start" && $# -gt 1 ]]; then
        echo "Syncing watson from Google Drive..."
        ${pkgs.rclone}/bin/rclone copy gdrive:watson ''${HOME}/.config/watson --include=frames 2>/dev/null
      fi
      command watson "$@"
    }
  '';
  # Push watson time log to Google Drive whenever frames file changes (e.g. after watson stop)
  systemd.user.services.watson-gdrive-sync = {
    Unit = {
      Description = "Push watson time log to Google Drive";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.rclone}/bin/rclone copy %h/.config/watson gdrive:watson --include=frames";
    };
  };

  systemd.user.paths.watson-gdrive-sync = {
    Unit.Description = "Watch watson frames file for changes";
    Path.PathChanged = "%h/.config/watson/frames";
    Install.WantedBy = [ "default.target" ];
  };
}
