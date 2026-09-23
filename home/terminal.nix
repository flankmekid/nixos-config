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
      confirm_os_window_close = 0;

      # Use the iGPU; kitty does not need the dGPU and this keeps it off.
      linux_display_server = "wayland";

      # ── Look
      background_opacity = "0.92";
      window_padding_width = 14;
      # A little more line spacing makes dense output easier to read.
      modify_font = "cell_height 112%";
      # Dim unfocused splits so the active one stands out.
      inactive_text_alpha = "0.75";
      url_style = "curly";

      # ── Cursor: thin blinking beam with a smooth trail.
      cursor_shape = "beam";
      cursor_beam_thickness = "1.8";
      cursor_blink_interval = "0.6";
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.4";

      # ── Tabs: only shown once there are two, numbered, active one bold.
      tab_bar_edge = "bottom";
      tab_bar_min_tabs = 2;
      tab_bar_style = "powerline";
      tab_powerline_style = "round";
      tab_title_template = "{index}: {title}";
      active_tab_font_style = "bold";
      inactive_tab_font_style = "normal";
    };
    keybindings = {
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+t" = "new_tab";
      "ctrl+equal" = "change_font_size all +1.0";
      "ctrl+minus" = "change_font_size all -1.0";
    };
  };
}
