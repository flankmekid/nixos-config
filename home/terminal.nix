{ config, pkgs, lib, ... }:
{
  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Mocha";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      # Smooth scrollback and a big buffer — you will be reading long nmap and
      # ffuf output constantly.
      scrollback_lines = 20000;
      scrollback_pager_history_size = 128;

      enable_audio_bell = false;
      window_padding_width = 8;
      confirm_os_window_close = 0;

      # Use the iGPU; kitty does not need the dGPU and this keeps it off.
      linux_display_server = "wayland";

      background_opacity = "0.92";
      cursor_trail = 1;

      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
    };
    keybindings = {
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+t" = "new_tab";
      "ctrl+equal" = "change_font_size all +1.0";
      "ctrl+minus" = "change_font_size all -1.0";
    };
  };
}
