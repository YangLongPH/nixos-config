{ pkgs, inputs, ... }:
let
  # nixpkgs pin chinh co glaze 8.x, nhung Hyprland v0.56.2 doi glaze 7.x
  # (xem note tren nixpkgs-glaze trong flake.nix). Lay glaze 7.9.1 tu nixpkgs
  # cu, override dung format ma overlay goc cua Hyprland dung
  # (enableSSL/enableInterop = false, xem nix/overlays.nix cua Hyprland).
  glazeCompat = inputs.nixpkgs-glaze.legacyPackages.${pkgs.system}.glaze.override {
    enableSSL = false;
    enableInterop = false;
  };

  hyprlandPackage = inputs.hyprland.packages.${pkgs.system}.hyprland.override {
    glaze-hyprland = glazeCompat;
  };
  # Hyprland >=0.56 mac dinh tim ~/.config/hypr/hyprland.lua truoc, bo qua
  # hyprland.conf co san (home-manager configType="hyprlang" sinh ra) ->
  # tu sinh config rong (mat plugin/exec-once/bind) neu khong co .lua.
  # Thay vi overrideAttrs Hyprland (se rebuild tu source, rat lau), tao rieng
  # 1 session package nho chi dich danh file .conf qua
  # "start-hyprland -- --config <path>", roi dat lam default session.
  hyprlandConfSession = pkgs.runCommand "hyprland-conf-session" {
    passthru.providedSessions = [ "hyprland-conf" ];
  } ''
    mkdir -p $out/share/wayland-sessions
    cat > $out/share/wayland-sessions/hyprland-conf.desktop <<EOF
    [Desktop Entry]
    Name=Hyprland (conf)
    Comment=Hyprland forced to load hyprland.conf instead of hyprland.lua
    Exec=${hyprlandPackage}/bin/start-hyprland -- --config /home/yanglong/.config/hypr/hyprland.conf
    Type=Application
    DesktopNames=Hyprland
    Keywords=tiling;wayland;compositor;
    EOF
  '';
in
{
  programs.hyprland = {
    enable = true;
    package = hyprlandPackage;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  services.displayManager.sessionPackages = [ hyprlandConfSession ];
  services.displayManager.defaultSession = "hyprland-conf";

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    config = {
      common.default = [ "gtk" ];
      hyprland.default = [
        "gtk"
        "hyprland"
      ];
    };

    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
