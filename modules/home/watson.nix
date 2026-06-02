{ pkgs, ... }:
{
  home.file.".local/bin/watson-waybar" = {
    executable = true;
    text = ''
      #!/bin/sh
      state="$HOME/.config/watson/state"
      [ -f "$state" ] || exit 0

      start=$(grep -oP '"start":\s*\K[0-9]+' "$state" 2>/dev/null)
      project=$(grep -oP '"project":\s*"\K[^"]+' "$state" 2>/dev/null)
      [ -z "$start" ] || [ -z "$project" ] && exit 0

      elapsed=$(( $(date +%s) - start ))
      elapsed_fmt=$(printf '%02d:%02d:%02d' $((elapsed/3600)) $(( (elapsed%3600)/60 )) $((elapsed%60)))

      mode=$(cat /tmp/watson-waybar-mode 2>/dev/null || echo "time")
      if [ "$mode" = "project" ]; then
        printf '%s\n' "$project"
      else
        printf '%s\n' "$elapsed_fmt"
      fi
    '';
  };

  home.file.".local/bin/watson-waybar-toggle" = {
    executable = true;
    text = ''
      #!/bin/sh
      mode_file="/tmp/watson-waybar-mode"
      mode=$(cat "$mode_file" 2>/dev/null || echo "time")
      if [ "$mode" = "time" ]; then
        echo "project" > "$mode_file"
      else
        echo "time" > "$mode_file"
      fi
      pkill -RTMIN+10 waybar
    '';
  };

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
