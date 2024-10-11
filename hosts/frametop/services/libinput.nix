{
  ...
}:

{
  services.libinput = {
    enable = true;
    touchpad = {
      accelProfile = "adaptive";
      disableWhileTyping = false;
      horizontalScrolling = true;
      leftHanded = false;
      middleEmulation = true;
      naturalScrolling = false;
      scrollMethod = "twofinger";
      sendEventsMode = "disabled-on-external-mouse";
      tapping = true;
    };
  };
}