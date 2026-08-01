{ ... }:
let
  modelsDir = "/var/lib/trellis";
  torchCacheDir = "/var/lib/trellis-torch";
in
{
  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
    "d ${torchCacheDir} 0755 root root -"
  ];
}
