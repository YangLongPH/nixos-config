{ ... }:
{
  xdg.configFile."fcitx5/config".text = ''
    [Hotkey]
    TriggerKeys=Control+space
    EnumerateWithTriggerKeys=True
    EnumerateSkipFirst=False
    PrevPage=Up
    NextPage=Down
    NextCandidate=Tab
    PrevCandidate=Shift+Tab
    ActivateKeys=
    DeactivateKeys=

    [Behavior]
    ShareInputState=No
    PreeditEnabledByDefault=True
    ShowInputMethodInformation=True
    ShowInputMethodInformationWhenFocusIn=False
    CompactInputMethodInformation=True
    ShowFirstInputMethodInformation=True
    DefaultPageSize=5
  '';

  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=unikey

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=unikey
    Layout=

    [GroupOrder]
    0=Default
  '';

xdg.configFile."fcitx5/conf/unikey.conf".text = ''
    [Unikey Engine]
    InputMethod=Telex
    OutputCharset=Unicode
    SpellingCheck=True
    MacroEnabled=False
    UseMouseCapture=False
  '';

  xdg.dataFile."fcitx5/addon/notificationitem.conf".text = ''
    [Addon]
    Enabled=False
  '';
}
