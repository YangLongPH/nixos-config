{ ... }:
{
  security = {
    rtkit.enable = true;
    sudo.enable = true;

    pam.services = {
      swaylock = { };
      hyprlock = { };
      login.enableGnomeKeyring = true;
      sddm.enableGnomeKeyring = true;
      "sddm-autologin".enableGnomeKeyring = true;
    };
  };
}
