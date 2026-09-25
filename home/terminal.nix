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
      # Hyprland tiles the windows. Remembering the last window's state makes
      # new kitty windows open maximized if the last one closed maximized.
      remember_window_size = false;

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
    # Caelestia's wallpaper colours, loaded at startup so new windows don't
    # flash the Catppuccin fallback above. Caelestia fills the template below
    # into this file on every scheme change; kitty skips it if it's missing.
    extraConfig = ''
      include ${config.xdg.stateHome}/caelestia/theme/kitty.conf
    '';
    keybindings = {
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+t" = "new_tab";
      "ctrl+equal" = "change_font_size all +1.0";
      "ctrl+minus" = "change_font_size all -1.0";
    };
  };

  xdg.configFile."caelestia/templates/kitty.conf".text = ''
    foreground #{{ onSurface.hex }}
    background #{{ surface.hex }}
    cursor #{{ secondary.hex }}
    selection_background #{{ secondary.hex }}
    color0 #{{ term0.hex }}
    color1 #{{ term1.hex }}
    color2 #{{ term2.hex }}
    color3 #{{ term3.hex }}
    color4 #{{ term4.hex }}
    color5 #{{ term5.hex }}
    color6 #{{ term6.hex }}
    color7 #{{ term7.hex }}
    color8 #{{ term8.hex }}
    color9 #{{ term9.hex }}
    color10 #{{ term10.hex }}
    color11 #{{ term11.hex }}
    color12 #{{ term12.hex }}
    color13 #{{ term13.hex }}
    color14 #{{ term14.hex }}
    color15 #{{ term15.hex }}
    color16 #{{ primary.hex }}
    color17 #{{ secondary.hex }}
    color18 #{{ tertiary.hex }}
  '';
}
