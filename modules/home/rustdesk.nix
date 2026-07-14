{ ... }:
{
  xdg.configFile."rustdesk/RustDesk.toml".text = ''
    [options]
    custom-rendezvous-server = "rustdesk.goline.vn"
    relay-server = "rustdesk.goline.vn"
    api-server = "https://rustdesk.goline.vn"
    key = "REPLACE_WITH_KEY_FROM_ADMIN"
  '';
}
