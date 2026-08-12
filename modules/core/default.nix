{ ... }:
{
  imports = [
    ./nixpkgs.nix
    ./bootloader.nix
    ./hardware.nix
    ./xserver.nix
    # ./plasma.nix
    ./network.nix
    ./bluetooth.nix
    ./fonts.nix
    ./nh.nix
    ./pipewire.nix
    ./program.nix
    ./security.nix
    ./services.nix
    ./steam.nix
    ./system.nix
    # ./flatpak.nix
    ./user.nix
    ./wayland.nix
    ./virtualization.nix
    # ./qmk.nix
    # ./piper.nix  # replaced by logiops
    ./logiops.nix
    ./input-method.nix
    # ./excalidraw.nix
  ];
}
