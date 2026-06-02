{ config, pkgs, username, ... }:
{
  nix.settings = {
    substituters = [ "https://cuda-maintainers.cachix.org" ];
    trusted-public-keys = [ "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" ];
  };

  nixpkgs.config.cudaSupport = true;
  nixpkgs.config.permittedInsecurePackages = [
    "cuda12.9-tensorrt-10.14.1.48"
  ];

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    cudaPackages.tensorrt
    curl
    curl.dev
    eigen
    opencv4
    nlohmann_json
    fmt
    fmt.dev
    spdlog
    spdlog.dev
    tbb
    tbb.dev
    zlib
    zlib.dev
  ];
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  powerManagement.cpuFreqGovernor = "performance";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "vi_VN";
    LC_IDENTIFICATION = "vi_VN";
    LC_MEASUREMENT = "vi_VN";
    LC_MONETARY = "vi_VN";
    LC_NAME = "vi_VN";
    LC_NUMERIC = "vi_VN";
    LC_PAPER = "vi_VN";
    LC_TELEPHONE = "vi_VN";
    LC_TIME = "vi_VN";
  };

  # NVIDIA GPU
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
  };

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings.monitor = [
      "HDMI-A-1,3840x2160@60,auto,1.67"
    ];
  };
}
