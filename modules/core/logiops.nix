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
                      keys = [ "KEY_LEFTCTRL" "KEY_LEFTALT" "KEY_UP" ];
                    };
                  }
                  {
                    direction = "Down";
                    mode = "OnRelease";
                    action = {
                      type = "Keypress";
                      keys = [ "KEY_LEFTCTRL" "KEY_LEFTALT" "KEY_DOWN" ];
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
