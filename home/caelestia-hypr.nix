# Hyprland config from the Caelestia dotfiles (Lua), with local overrides.
# home-manager does not write hyprland.conf or hyprland.lua any more.
{ pkgs, lib, inputs, ... }:
let
  # The Arch start commands do not work on NixOS. This file replaces them.
  # The Caelestia shell starts from its systemd user service, not from here.
  execs = pkgs.writeText "execs.lua" ''
    hl.on("hyprland.start", function()
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
        hl.exec_cmd("systemctl --user start hyprpolkitagent")
        hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    end)
  '';

  # hyprland.lua is a read-only store file, so HyprMod cannot add its include
  # line itself. Add it here. HyprMod writes ~/.config/hypr/hyprland-gui.lua,
  # which loads last, so GUI changes win over everything above it.
  hyprmodInclude = pkgs.writeText "hyprmod-include.lua" ''

    -- HyprMod managed settings
    maybe_create(hypr .. "/hyprland-gui.lua")
    require("hyprland-gui")
  '';

  hyprDots = pkgs.runCommand "caelestia-hypr" { } ''
    cp -r ${inputs.caelestia-dots}/hypr $out
    chmod -R u+w $out
    cp ${execs} $out/hyprland/execs.lua
    cp ${./hypr/keybinds.lua} $out/hyprland/keybinds.lua
    cp ${./hypr/gestures.lua} $out/hyprland/gestures.lua
    cat ${hyprmodInclude} >> $out/hyprland.lua
  '';

  # Same values as Caelestia's env.lua, except the Qt theme: the qtengine
  # plugin is not installed, and the system qt module uses gnome.
  uwsmEnvThemes = ''
    export QT_QPA_PLATFORMTHEME='gnome'
    export QT_WAYLAND_DISABLE_WINDOWDECORATION='1'
    export QT_AUTO_SCREEN_SCALE_FACTOR='1'
  '';
in
{
  # Stop the home-manager Hyprland generator. Caelestia's Lua config is used.
  wayland.windowManager.hyprland.enable = lib.mkForce false;

  # recursive = true makes real directories, so Caelestia can write
  # hypr/scheme/current.lua when you change the colour scheme.
  xdg.configFile."hypr" = {
    source = hyprDots;
    recursive = true;
  };

  # uwsm reads these for the whole session (systemd user services included).
  xdg.configFile."uwsm/env".text = uwsmEnvThemes;
  xdg.configFile."uwsm/env-hyprland".text = ''
    export GDK_BACKEND='wayland,x11'
    export QT_QPA_PLATFORM='wayland;xcb'
    export SDL_VIDEODRIVER='wayland,x11,windows'
    export CLUTTER_BACKEND='wayland'
    export ELECTRON_OZONE_PLATFORM_HINT='auto'

    export XDG_CURRENT_DESKTOP=Hyprland
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=Hyprland

    export _JAVA_AWT_WM_NONREPARENTING=1
  '';

  # Values that replace the defaults in hypr/variables.lua.
  xdg.configFile."caelestia/hypr-vars.lua".text = ''
    return {
        terminal              = "kitty",
        browser               = "zen-beta",
        editor                = "codium",
        fileExplorer          = "nautilus",
        cursorTheme           = "Bibata-Modern-Classic",
        cursorSize            = 24,
        sleepGestureCmd       = "systemctl suspend",

        -- 3-finger horizontal swipe changes workspace. 3-finger up/down
        -- still toggles the special workspace (different direction).
        workspaceSwipeFingers = 3,

        -- SUPER + SHIFT + 1-9/0 moves the window to that workspace.
        kbMoveWinToWs         = "SUPER + SHIFT",

        -- Solid windows (default 0.95). Kitty stays see-through through
        -- its own background_opacity, which only fades the background.
        windowOpacity         = 1.0,
    }
  '';

  # Your own Hyprland settings. They load after the Caelestia config.
  xdg.configFile."caelestia/hypr-user.lua".text = ''
    -- Internal panel: 2560x1600 at 16". 1.333333 divides the resolution
    -- exactly (1920x1200 logical). Other clean values: 1.25 (2048x1280),
    -- 1.6 (1600x1000).
    hl.monitor({
        output   = "eDP-1",
        mode     = "2560x1600@165",
        position = "0x0",
        scale    = 1.333333,
    })

    hl.config({
        -- Stop Hyprland from upscaling XWayland apps (Steam, older
        -- Java/Electron), which makes them blurry at fractional scale.
        xwayland = { force_zero_scaling = true },

        -- Lets the `immediate` rule on the Caelestia "game" tag work.
        general  = { allow_tearing = true },

        input    = {
            kb_layout  = "us,ro",
            kb_variant = ",std",
            kb_options = "grp:alt_shift_toggle,caps:escape",
        },
    })

    hl.env("QT_QPA_PLATFORMTHEME", "gnome")

    -- Launcher and shell restart binds are in home/hypr/keybinds.lua.
  '';
}
