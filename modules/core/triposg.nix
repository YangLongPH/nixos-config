{ ... }:
let
  modelsDir = "/var/lib/triposg";
in
{
  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
