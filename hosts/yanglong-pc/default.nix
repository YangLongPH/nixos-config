{ config, lib, pkgs, username, ... }:
{
  nix.settings = {
    substituters = [ "https://cuda-maintainers.cachix.org" ];
    trusted-public-keys = [ "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" ];
  };

  nixpkgs.config.cudaSupport = true;
  nixpkgs.config.cudaCapabilities = [ "8.9" ];
  nixpkgs.config.cudaForwardCompat = false;
  nixpkgs.config.permittedInsecurePackages = [
    "cuda12.9-tensorrt-10.14.1.48"
  ];

  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    nvidia-container-toolkit.tools
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
    ffmpeg-full
  ];
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./../../modules/core/trellis.nix
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # services.calibre-web = {
  #   enable = true;
  #   listen.ip = "0.0.0.0";
  #   listen.port = 8083;
  #   openFirewall = true;
  #   options = {
  #     calibreLibrary = "/var/lib/calibre-web/library";
  #     enableBookUploading = true;
  #   };
  # };

  # systemd.tmpfiles.rules = [
  #   "d /var/lib/calibre-web/library 0755 calibre-web calibre-web -"
  # ];

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
  hardware.nvidia-container-toolkit.enable = true;
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
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      "/run/opengl-driver"
      pkgs.cudaPackages.cudatoolkit
      pkgs.cudaPackages.cudnn
      pkgs.ffmpeg-full
      pkgs.libwebp
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      "~/.local/lib/ort-gpu"
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings.monitor = [
      "HDMI-A-1,3840x2160@60,auto,1.67"
    ];
  };
}
