{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # Bootloader config driver for usb tp-link archer T2U Nano 
  # boot.extraModulePackages = [ config.boot.kernelPackages.rtl8821cu ];
  # boot.blacklistedKernelModules = [ "rtw88_8821cu" "rtw88_8821c" ];

  # Lock wired metric via dhcpcd (dhcpcd manages enp34s0)
  networking.dhcpcd.extraConfig = ''
    interface enp34s0
    metric 700
  '';

  # Lock WiFi metric — modify existing NM profile, no need to redefine password
  system.activationScripts.nmWifiMetric = {
    deps = [ "etc" ];
    text = ''
      ${pkgs.networkmanager}/bin/nmcli connection modify "Goline" ipv4.route-metric 100 2>/dev/null || true
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
