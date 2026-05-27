{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.extraModulePackages = [ config.boot.kernelPackages.rtl8821cu ];
  boot.blacklistedKernelModules = [ "rtw88_8821cu" "rtw88_8821c" ];

  # Overide network metic by dhcpcd
  networking.dhcpcd.extraConfig = ''
    interface enp34s0
    metric 200
    interface wlp22s0f0u5i2
    metric 100
  '';

  # Overide network metric
  # systemd.network.networks = {
  #   "10-wifi" = {
  #     matchConfig.Name = "wlp*";
  #     networkConfig.DHCP = "ipv4";
  #     dhcpV4Config.RouteMetric = 100;  # lower = higher priority
  #   };
  #   "20-eth" = {
  #     matchConfig.Name = "enp34s0";
  #     networkConfig.DHCP = "ipv4";
  #     dhcpV4Config.RouteMetric = 200;
  #   };
  # };
  # networking.useNetworkd = true;
}
