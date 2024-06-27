# FFmpeg is the leading multimedia framework, able to decode, encode, transcode, mux, demux, stream, filter and play pretty much anything that humans and machines have created.
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    ffmpeg
    ffmpegthumbs
  ];
}
