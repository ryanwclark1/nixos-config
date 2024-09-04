# A plain text note-taking assistant
{
  pkgs,
  ...
}:

{
  programs = {
    zk = {
      enable = true;
      package = pkgs.zk;
      settings = {
         note = {
          language = "en";
          default-title = "Untitled";
          filename = "{{id}}-{{slug title}}";
          extension = "md";
          template = "default.md";
          id-charset = "alphanum";
          id-length = 4;
          id-case = "lower";
        };
        extra = {
          author = "Ryan";
        };
      };
    };
  };
}