{ ... }:
let
  modelsDir = "/var/lib/hunyuan3d";
in
{
  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
