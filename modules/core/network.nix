{ pkgs, host, config, username, ... }:
{
  # Prevent deadlock during nixos-rebuild switch: switch-to-configuration stops NM
  # then blocks waiting for network-online.target → NM-wait-online → NM (already stopped).
  systemd.services.NetworkManager-wait-online.enable = false;

  networking = {
    hostName = "${host}";
    networkmanager.enable = true;
    enableIPv6 = false;
    hosts = {
      "10.10.1.24" = [ "vtrade-psi.goline.vn" "vapi-psi.goline.vn" "vwss-psi.goline.vn" ];
      "10.10.1.25" = [ "vgapi-psi.goline.vn" ];
      "10.10.1.26" = [ "vgaia-psi.goline.vn" "wiki.goline.vn" "sso.goline.vn" ];
      "10.10.1.27" = [ "vmarket-psi.goline.vn" ];
      "192.168.2.5" = [ "rustdesk.goline.vn" ];
    };
    # nameservers = [
    #   "8.8.8.8"
    #   "8.8.4.4"
    #   "1.1.1.1"
    # ];
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      # allowedTCPPorts = [
      #   22
      #   80
      #   443
      #   59010
      #   59011
      # ];
      # allowedUDPPorts = [
      #   59010
      #   59011
      # ];
    };
  };

  # Auto proxy via wired when WiFi is down.
  # Manages: Hyprland env (GUI apps), flag file (terminal precmd hook).
  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeShellScript "wired-proxy" ''
      IFACE="$1"
      EVENT="$2"

      [[ "$IFACE" != wl* ]] && exit 0

      USER_UID=$(id -u ${username})
      RUNTIME_DIR="/run/user/$USER_UID"
      HOME_DIR="/home/${username}"
      PROXY_URL="http://10.10.1.90:3128/"
      NO_PROXY_VAL="localhost,127.0.0.1,192.168.1.*,10.10.*,.goline,*.goline.vn"
      FLAG="$HOME_DIR/.cache/wired-proxy-active"
      HYPR_INSTANCE=$(ls "$RUNTIME_DIR/hypr/" 2>/dev/null | head -1)

      as_user() {
        su -s /bin/sh ${username} -c "XDG_RUNTIME_DIR=$RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS=unix:path=$RUNTIME_DIR/bus HYPRLAND_INSTANCE_SIGNATURE=$HYPR_INSTANCE $1"
      }

      enable_proxy() {
        mkdir -p "$(dirname "$FLAG")"
        touch "$FLAG" && chown ${username} "$FLAG"
        if [[ -n "$HYPR_INSTANCE" ]]; then
          as_user "hyprctl keyword env 'HTTP_PROXY,$PROXY_URL'" || true
          as_user "hyprctl keyword env 'HTTPS_PROXY,$PROXY_URL'" || true
          as_user "hyprctl keyword env 'http_proxy,$PROXY_URL'" || true
          as_user "hyprctl keyword env 'https_proxy,$PROXY_URL'" || true
          as_user "hyprctl keyword env 'NO_PROXY,$NO_PROXY_VAL'" || true
          as_user "hyprctl keyword env 'no_proxy,$NO_PROXY_VAL'" || true
        fi
        as_user "notify-send 'Proxy ON' 'WiFi off. Wired proxy active. Restart Chrome if needed.'" || true
      }

      disable_proxy() {
        rm -f "$FLAG"
        if [[ -n "$HYPR_INSTANCE" ]]; then
          as_user "hyprctl keyword unsetenv HTTP_PROXY" || true
          as_user "hyprctl keyword unsetenv HTTPS_PROXY" || true
          as_user "hyprctl keyword unsetenv http_proxy" || true
          as_user "hyprctl keyword unsetenv https_proxy" || true
          as_user "hyprctl keyword unsetenv NO_PROXY" || true
          as_user "hyprctl keyword unsetenv no_proxy" || true
        fi
        as_user "notify-send 'Proxy OFF' 'WiFi on. Direct connection. Restart Chrome if needed.'" || true
      }

      case "$EVENT" in
        down) enable_proxy ;;
        up)   disable_proxy ;;
      esac
    '';
    type = "basic";
  }];

  environment.systemPackages = with pkgs; [ networkmanagerapplet libnotify ];
}
