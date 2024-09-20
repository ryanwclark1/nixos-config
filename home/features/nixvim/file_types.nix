
_:

{
  programs.nixvim.autoGroups = {
    filetypes = {};
  };

  programs.nixvim.files."ftdetect/terraformft.lua".autoCmd = [
    {
      group = "filetypes";
      event = ["BufRead" "BufNewFile"];
      pattern = ["*.tf" " *.tfvars" " *.hcl"];
      command = "set ft=terraform";
    }
  ];

  programs.nixvim.files."ftdetect/bicepft.lua".autoCmd = [
    {
      group = "filetypes";
      event = ["BufRead" "BufNewFile"];
      pattern = ["*.bicep" "*.bicepparam"];
      command = "set ft=bicep";
    }
  ];
}
