{ pkgs, host, config, ... }:
{
  networking = {
    hostName = "${host}";
    networkmanager.enable = true;
    enableIPv6 = false;
    hosts = {
      "10.10.1.24" = [ "vtrade-psi.goline.vn" "vapi-psi.goline.vn" "vwss-psi.goline.vn" ];
      "10.10.1.25" = [ "vgapi-psi.goline.vn" ];
      "10.10.1.26" = [ "vgaia-psi.goline.vn" ];
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

  environment.systemPackages = with pkgs; [ networkmanagerapplet ];
}
