{ ... }:
{
  # RustDesk is started via Hyprland exec-once (see hyprland/exec-once.nix)
  # so it inherits the full Wayland session environment.
  #
  # RustDesk config is NOT managed by home-manager — RustDesk needs write
  # access to persist its ID. Configure server once via GUI after first boot:
  #   Settings → Network → ID/Relay server
  #   ID server:    rustdesk.goline.vn
  #   Relay server: rustdesk.goline.vn
  #   API server:   https://rustdesk.goline.vn
  #   Key:          <key from admin>
}
