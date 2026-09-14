{ pkgs, lib, ... }:
let
  profilesDir = ./profiles;
  profiles = builtins.readDir profilesDir;
  remminaFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".remmina" name) profiles;
in
{
  home.packages = [ pkgs.remmina ];

  home.file = lib.mapAttrs' (name: _: {
    name = ".local/share/remmina/${name}";
    value.source = "${profilesDir}/${name}";
  }) remminaFiles;
}
