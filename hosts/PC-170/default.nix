{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # rtl8821cu (out-of-tree) driver dedicated to the USB TP-Link Archer T2U Nano.
  # The in-tree rtw88_8821cu/rtw88_8821c driver must be blacklisted since it caused
  # periodic disconnections - the out-of-tree driver is stable (paired with the
  # powersave/autosuspend fixes below).
  boot.extraModulePackages = [ config.boot.kernelPackages.rtl8821cu ];
  # rtl8188ee = internal PCI wifi card, confirmed dead hardware (RF path dead, 0 rx/tx,
  # scans find zero APs even though driver/firmware load cleanly) - blacklisted so the
  # kernel stops loading a driver for it; switched permanently to the USB Archer T2U Nano above.
  boot.blacklistedKernelModules = [ "rtw88_8821cu" "rtw88_8821c" "rtl8188ee" ];

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
  # Disable WiFi power management to prevent periodic disconnection on rtl8821cu
  networking.networkmanager.wifi.powersave = false;

  # Disable USB autosuspend for the TP-Link Archer T2U Nano (RTL8821CU)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2357", ATTR{idProduct}=="0120", TEST=="power/control", ATTR{power/control}="on"
  '';

  # Prevent kernel from suspending the USB WiFi adapter
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];
}
