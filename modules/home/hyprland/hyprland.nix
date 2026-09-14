{ pkgs, inputs, ... }:
let
  # glaze 7.9.1 override: nixpkgs bump glaze 8.0.0 (03/08) 2 ngay truoc khi
  # Hyprland v0.56.2 release (05/08). CMakeLists.txt Hyprland doi
  # find_package(glaze 7...<8), nen nixpkgs pin chinh (glaze 8.x) khong thoa
  # man -> fallback FetchContent (git clone) -> fail trong sandbox.
  # Dung chung 1 ban Hyprland da fix cho ca package chinh lan hy3 (hy3 tu
  # keo rieng 1 ban Hyprland goc de build plugin, khong tu dung override nay
  # neu khong duoc truyen thang vao).
  glazeCompat = inputs.nixpkgs-glaze.legacyPackages.${pkgs.system}.glaze.override {
    enableSSL = false;
    enableInterop = false;
  };
  hyprlandFixed = inputs.hyprland.packages.${pkgs.system}.hyprland.override {
    glaze-hyprland = glazeCompat;
  };
  hy3Fixed = inputs.hy3.packages.${pkgs.system}.hy3.override {
    hyprland = hyprlandFixed;
  };
in
{
  home.packages = with pkgs; [
    awww
    grimblast
    hyprpicker
    grim
    slurp
    wl-clip-persist
    cliphist
    wf-recorder
    glib
    wayland
    direnv
    tesseract
  ];
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprlandFixed;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;

    # hy3 gay SEGV lap lai khi man hinh reconnect sau idle/DPMS wake
    # (CMonitor::onConnect -> applyMonitorRule -> getViewsForWorkspace, null deref).
    # Xem crash report: ~/.cache/hyprland/hyprlandCrashReport*.txt (vd 2265, 2349).
    # Da bump hyprland/hy3/aquamarine len ban moi nhat (2026-09) de thu fix; neu con
    # tai dien, thu tat plugin hy3 de xac nhan thu pham roi bao upstream.
    extraConfig = ''
      plugin = ${hy3Fixed}/lib/libhy3.so
    '';

    configType = "hyprlang";

    xwayland = {
      enable = true;
      # hidpi = true;
    };
    # enableNvidiaPatches = false;
    systemd.enable = true;
  };
}
