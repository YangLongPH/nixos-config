{ pkgs, username, ... }:
{
  # Add user to libvirtd group
  users.users.${username}.extraGroups = [
    "libvirtd"
    "docker"
  ];

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    # virtio-win
    win-spice
    adwaita-icon-theme
    # Ansible + VM test tooling
    ansible
    sshpass
    cloud-utils  # cung cấp cloud-localds để tạo cloud-init seed ISO
  ];

  # Manage the virtualisation services
  virtualisation = {
    docker = {
      enable = true;
      daemon.settings = {
        dns = [ "192.168.89.1" "8.8.8.8" ];
        features.cdi = true;
        runtimes.nvidia = {
          path = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
          runtimeArgs = [];
        };
      };
    };
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
}
