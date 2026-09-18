{
  inputs,
  pkgs,
  system,
  ...
}:
{
  _2048 = pkgs.callPackage ./2048 { stdenv = pkgs.gcc14Stdenv; };
  maple-mono-custom = pkgs.callPackage ./maple-mono { inherit inputs; };
  nexus3-cli = pkgs.callPackage ./nexus3-cli { };
  pomo = pkgs.callPackage ./pomo { };
  jk = pkgs.callPackage ./jk { };
}
