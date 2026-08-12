{ pkgs, ... }:
{
  services.logiops = {
    enable = true;
    package = pkgs.logiops;
    # Run `sudo logid -v` to find exact device name and button CIDs
    config = {
      devices = [
        {
          name = "MX Master 3S";
          smartshift = {
            on = true;
            threshold = 30;
          };
          hiresscroll = {
            hires = true;
            invert = false;
            target = false;
          };
          buttons = [
            {
              # Back button — CID 0x53 = 83
              cid = 83;
              action = {
                type = "Keypress";
                keys = [ "KEY_PAGEDOWN" ];
              };
            }
            {
              # Forward button — CID 0x56 = 86
              cid = 86;
              action = {
                type = "Keypress";
                keys = [ "KEY_PAGEUP" ];
              };
            }
            {
              # Shift wheel button — CID 0xc4 = 196
              cid = 196;
              action = {
                type = "Keypress";
                keys = [ "KEY_RIGHT" ];
              };
            }
            {
              # Gesture button (dưới scroll wheel) — CID 0xc3 = 195
              cid = 195;
              action = {
                type = "Gestures";
                gestures = [
                  {
                    direction = "None";
                    mode = "OnRelease";
                    action = {
                      type = "Keypress";
                      keys = [ "KEY_LEFTMETA" "KEY_D" ];
                    };
                  }
                  {
                    direction = "Left";
                    mode = "OnRelease";
                    action = {
                      type = "Keypress";
                      keys = [ "KEY_LEFTCTRL" "KEY_LEFTALT" "KEY_LEFT" ];
                    };
                  }
                  {
                    direction = "Right";
                    mode = "OnRelease";
                    action = {
                      type = "Keypress";
                      keys = [ "KEY_LEFTCTRL" "KEY_LEFTALT" "KEY_RIGHT" ];
                    };
                  }
                  {
                    direction = "Up";
                    mode = "OnRelease";
                    action = {
                      type = "Keypress";
                      keys = [ "KEY_LEFTCTRL" "KEY_LEFTSHIFT" "KEY_T" ];
                    };
                  }
                  {
                    direction = "Down";
                    mode = "OnRelease";
                    action = {
                      type = "Keypress";
                      keys = [ "KEY_LEFTCTRL" "KEY_LEFTSHIFT" "KEY_W" ];
                    };
                  }
                ];
              };
            }
          ];
        }
      ];
    };
  };
}
