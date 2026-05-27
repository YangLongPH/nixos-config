{ ... }:
{
  systemd.user.services.wallpaper-rotate = {
    Unit = {
      Description = "Set a random wallpaper";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin";
      ExecStart = "/etc/profiles/per-user/%u/bin/random-wallpaper";
    };
  };

  systemd.user.timers.wallpaper-rotate = {
    Unit.Description = "Auto-rotate wallpaper every minute";
    Timer = {
      OnActiveSec = "1min";
      OnUnitActiveSec = "1min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
