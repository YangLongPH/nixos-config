{ ... }:
{
  security = {
    rtkit.enable = true;
    sudo.enable = true;
    sudo.extraConfig = ''
      Defaults env_keep += "HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy"
    '';

    pam.services = {
      swaylock = { };
      hyprlock = { };
    };
  };
}
