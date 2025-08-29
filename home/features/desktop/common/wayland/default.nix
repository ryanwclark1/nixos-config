{
  pkgs,
  ...
}:

{
  # Truly universal Wayland tools that work with any compositor/DE
  home.packages = with pkgs; [
    # Universal clipboard utilities
    wl-clipboard
    
    # Universal screenshot and recording tools  
    grim      # Screenshot utility for Wayland
    slurp     # Screen region selector for Wayland
    wf-recorder # Screen recording for Wayland
    
    # Universal audio tools
    pwvucontrol # PipeWire volume control
    
    # Universal Wayland utilities
    waypipe   # Network proxy for Wayland clients
    wayland-utils # Wayland debugging and info utilities
  ];
}