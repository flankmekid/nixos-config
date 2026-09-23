# ── Clipboard history with image previews ────────────────────────────────────
# clipse runs in a floating kitty window (SUPER + V, see home/hypr/keybinds.lua)
# and shows images inline with kitty's graphics protocol. Its listener keeps
# its own history; cliphist still runs for Caelestia's "type latest" bind.
{ ... }:
{
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
