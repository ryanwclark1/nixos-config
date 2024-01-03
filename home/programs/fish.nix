{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib; {
  options.fish.enable = mkEnableOption "fish enable";

  config = mkIf config.fish.enable {
    programs.fish = {
      enable = true;
      plugins = [
        {
          name = "fish-autopair";
          src = pkgs.fishPlugins.autopair;
        }
        {
          name = "fish-done";
          src = pkgs.fishPlugins.done;
        }
        {
          name = "fish-fzf";
          src = pkgs.fishPlugins.fzf;
        }
        {
          name = "fish-grc";
          src = pkgs.fishPlugins.grc;
        }
        {
          name = "fish-sponge";
          src = pkgs.fishPlugins.sponge;
        }
        {
          name = "fish-puffer";
          src = pkgs.fishPlugins.puffer;
        }
        {
          name = "fish-fzf-fish";
          src = pkgs.fishPlugins.fzf-fish;
        }
        {
          name = "fish-colored-man-pages";
          src = pkgs.fishPlugins.colored-man-pages;
        }
        {
          name = "fish-catppuccin";
          src = inputs.catppuccin-fish;
        }
      ];
      interactiveShellInit = ''

        fish_config theme choose "Base16 Default Dark"

         set -Ux FZF_DEFAULT_OPTS "\
         --color=bg+:#313244,bg:${config.colors.macchiato.base.hex},spinner:#f5e0dc,hl:#f38ba8 \
         --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
         --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

         # eval (zellij setup --generate-completion fish | string collect)
      '';
      shellAbbrs = {
        # hxi = "${config.editor.terminal} $(${pkgs.gum}/bin/gum file -a)";
        # h = "${config.editor.terminal} $(${pkgs.gum}/bin/gum file -a)";
        # sw = "sudo nixos-rebuild switch --flake ~/willow/#";
        # swf = "sudo nixos-rebuild switch --flake ~/willow/# --fast";
        # v2 = "${pkgs.v2ray}/bin/v2ray run -c ~/vless-hackap.json";
        # new-pro = "cat vless-hackap.json | ${pkgs.jq}/bin/jq .outbounds=\"$(wl-paste | ${pkgs.jq}/bin/jq .outbounds)\" > vless-hackap.json";
      };
    };

    programs.fzf.enableFishIntegration = config.fzf.enable;
    # programs.nix-index.enableFishIntegration = true;
    programs.starship.enableFishIntegration = config.starship.enable;
    # programs.zoxide.enableFishIntegration = config.zoxide.enable;
    # services.gpg-agent.enableFishIntegration = config.gpg.enable;
    home.sessionVariables = {
      fish_greeting = "";
      fish_tmux_config = "$HOME/.config/tmux/tmux.conf";
      fish_tmux_autoconnect = "false";
    };
  };
}