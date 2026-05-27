{ pkgs, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.configurationLimit = 10;
    };

    kernelPackages = pkgs.linuxPackages_7_0;
    kernelModules = [ "hid-nintendo" ];
    supportedFilesystems = [ "ntfs" ];
  };
}
