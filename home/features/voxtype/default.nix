{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  voxtypePkg = inputs.voxtype.packages.${system}.vulkan;

  whisperModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin";
    sha256 = "0mj3vbvaiyk5x2ids9zlp2g94a01l4qar9w109qcg3ikg0sfjdyc";
  };

  vadModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin";
    sha256 = "11v9zgvwkihs750kmdiswd49q7bwvwfm081sk213mdgfhnvnk8ia";
  };

  # Manually generate the config file since we're bypassing the module to avoid service conflicts
  configFile = pkgs.writeText "voxtype-config.toml" ''
    engine = "whisper"
    state_file = "auto"

    [hotkey]
    enabled = false

    [audio]
    device = "default"
    sample_rate = 16000
    max_duration_secs = 180

    [audio.feedback]
    enabled = false
    theme = "default"
    volume = 0.7

    [whisper]
    model = "${whisperModel}"
    language = "en"
    translate = false
    flash_attention = true
    gpu_isolation = true

    [output]
    mode = "type"
    driver_order = ["wtype", "ydotool", "clipboard"]
    fallback_to_clipboard = true
    type_delay_ms = 2
    pre_type_delay_ms = 500
    restore_clipboard = false
    restore_clipboard_delay_ms = 200
    append_text = " "
    smart_auto_submit = true

    [output.notification]
    on_recording_start = false
    on_recording_stop = false
    on_transcription = true

    [vad]
    enabled = true
    backend = "whisper"
    model = "${vadModel}"
    threshold = 0.5

    [status]
    icon_theme = "emoji"

    [integration]
    state_file = "auto"

    [text]
    # spoken_punctuation = false
    replacements = { "hyperwhisper" = "hyprwhspr" }
  '';
in
{
  home.packages = with pkgs; [
    voxtypePkg
    # voxtype
    wtype
    wl-clipboard
  ];

  home.activation.createStatusFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.local/state/voxtype/"
    $DRY_RUN_CMD touch "$HOME/.local/state/voxtype/status"
    $DRY_RUN_CMD chmod 600 "$HOME/.local/state/voxtype/status"
  '';

  systemd.user.services.voxtype = {
    Unit = {
      Description = "VoxType push-to-talk voice-to-text daemon";
      Wants = [
        "pipewire.service"
        "pipewire-pulse.service"
        "wireplumber.service"
      ];
      After = [
        "graphical-session.target"
        "pipewire.service"
        "pipewire-pulse.service"
        "wireplumber.service"
      ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Service = {
      ExecStart = "${voxtypePkg}/bin/voxtype --config ${configFile} daemon";
      Environment = [
        "PATH=${lib.makeBinPath [ pkgs.wtype pkgs.wl-clipboard ]}:/run/current-system/sw/bin"
      ];
      ExecSearchPath = "${pkgs.wtype}/bin:${pkgs.wl-clipboard}/bin";
      Restart = "always";
      RestartSec = "3";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
