{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # Internal wifi upgraded: dead RTL8188EE physically replaced with Intel AX210
  # (iwlwifi driver, in-tree, zero extra config needed - just works).
  #
  # USB TP-Link Archer T2U Nano kept as spare, currently unplugged. If it's
  # plugged back in, uncomment below (in-tree rtw88_8821cu/rtw88_8821c caused
  # periodic disconnections, hence the out-of-tree driver + blacklist):
  # boot.extraModulePackages = [ config.boot.kernelPackages.rtl8821cu ];
  # boot.blacklistedKernelModules = [ "rtw88_8821cu" "rtw88_8821c" ];

  # Lock metrics via NM (dhcpcd is inactive, NM manages all interfaces)
  system.activationScripts.nmWifiMetric = {
    deps = [ "etc" ];
    text = ''
      ${pkgs.networkmanager}/bin/nmcli connection modify "Goline" ipv4.route-metric 100 2>/dev/null || true
      ${pkgs.networkmanager}/bin/nmcli connection modify "wired-170" ipv4.route-metric 700 2>/dev/null || true
    '';
  };

  networking.hosts = {
    "10.10.1.249" = [ "gitlab.goline.vn" ];
    "10.10.1.24" = [ "repository.goline.vn" ];
    "10.10.1.26" = [ "pass.goline.vn" ];
    "192.168.2.24" = [ "jarvis.goline.vn" ];
  };
  networking.networkmanager.wifi.macAddress = "permanent";

  # Below are workarounds specific to the USB Archer T2U Nano (RTL8821CU);
  # not needed for the Intel AX210. Re-enable if the dongle is plugged back in.
  # networking.networkmanager.wifi.powersave = false;  # prevent periodic disconnection on rtl8821cu
  # services.udev.extraRules = ''
  #   ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2357", ATTR{idProduct}=="0120", TEST=="power/control", ATTR{power/control}="on"
  # '';
  # boot.kernelParams = [ "usbcore.autosuspend=-1" ];
}
