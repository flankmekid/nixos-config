# ── Clipboard history with image previews ────────────────────────────────────
# SUPER + V:          Vicinae's clipboard history: a launcher-style popup with
#                     search and a full preview of images. Vicinae keeps its
#                     own history from when its server (below) starts.
# SUPER + SHIFT + V:  clipse in a floating kitty window; images show inline via
#                     kitty's graphics protocol. Its listener keeps its own
#                     history.
# Binds are in home/hypr/keybinds.lua.
{ ... }:
{
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
    };
    # Written to ~/.config/vicinae/settings.json, so changes made in
    # Vicinae's own settings screen do not stick; set them here.
    settings = {
      # Its tray icon has no image in Caelestia's bar.
      tray.enabled = false;
      # No global shortcut (default Alt + Space); SUPER + V opens the clipboard.
      global_shortcuts.toggle = "";
      theme.dark.name = "catppuccin-mocha";
    };
  };

  services.clipse = {
    enable = true;
    settings = {
      maxHistory = 200;
      allowDuplicates = false;
      imageDisplay = {
        type = "kitty";
        scaleX = 9;
        scaleY = 9;
        heightCut = 2;
      };
    };
    # Catppuccin Mocha.
    theme = {
      useCustomTheme = true;
      TitleFore = "#cdd6f4";
      Titleback = "#cba6f7";
      NormalTitle = "#cdd6f4";
      NormalDesc = "#6c7086";
      DimmedTitle = "#7f849c";
      DimmedDesc = "#585b70";
      SelectedTitle = "#f5c2e7";
      SelectedDesc = "#b4befe";
      SelectedBorder = "#cba6f7";
      SelectedDescBorder = "#b4befe";
      FilteredMatch = "#a6e3a1";
      StatusMsg = "#89b4fa";
      PinIndicatorColor = "#fab387";
    };
  };
}
