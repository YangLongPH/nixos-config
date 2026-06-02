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

  # Overide network metic by dhcpcd
  networking.dhcpcd.extraConfig = ''
    interface enp34s0
    metric 200
    interface wlp35s0
    metric 100
  '';
  # networking.networkmanager.ensureProfiles = {
  #   environmentFiles = [ "/etc/networkmanager/wifi-secrets.env" ];
  #   profiles = {
  #     "wired-170" = {
  #       connection = {
  #         id = "wired-170";
  #         type = "ethernet";
  #         "interface-name" = "enp34s0";
  #       };
  #       ipv4 = {
  #         method = "auto";
  #         "route-metric" = "200";
  #       };
  #     };
  #     "Goline" = {
  #       connection = {
  #         id = "Goline";
  #         type = "wifi";
  #       };
  #       wifi = {
  #         ssid = "Goline";
  #         mode = "infrastructure";
  #       };
  #       "wifi-security" = {
  #         "key-mgmt" = "wpa-psk";
  #         psk = "$GOLINE_PASSWORD";
  #       };
  #       ipv4 = {
  #         method = "auto";
  #         "route-metric" = "100";
  #       };
  #     };
  #   };
  # };

  networking.hosts = {
    "10.10.1.249" = [ "gitlab.goline.vn" ];
    "10.10.1.24" = [ "repository.goline.vn" ];
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
