# ── Hyprland user configuration ───────────────────────────────────────────────
#
# Caelestia provides the bar, launcher, notifications, lock screen and
# wallpaper. This file is only the compositor: monitors, input, keybinds,
# window rules. Keep the two responsibilities separate and upgrades stay easy.
{ config, pkgs, lib, inputs, system, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;

    # uwsm owns the session (programs.hyprland.withUWSM at system level), so
    # home-manager must NOT also start hyprland itself.
    systemd.enable = false;

    settings = {
      # ── Monitors
      # `preferred` picks the panel's native mode+refresh, so the Legion's
      # 144/165Hz display is used properly without hardcoding a resolution.
      # Run `hyprctl monitors` on the real machine to add external displays.
      monitor = [
        "eDP-1,preferred,auto,1.0"
        ",preferred,auto,1.0" # any external display: native mode, auto position
      ];

      # ── Autostart
      "exec-once" = [
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "systemctl --user start hyprpolkitagent"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];

      # ── Input
      input = {
        kb_layout = "us,ro";
        kb_variant = ",std";
        kb_options = "grp:alt_shift_toggle,caps:escape";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap-to-click = true;
          clickfinger_behavior = true; # two-finger click = right click
          scroll_factor = 0.8;
        };
      };

      gestures.workspace_swipe = true;

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(cba6f7ee) rgba(89b4faee) 45deg"; # catppuccin mocha
        "col.inactive_border" = "rgba(45475aaa)";
        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = true; # lets games opt into tearing for lower latency
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 12;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "wind,0.05,0.9,0.1,1.05"
          "overshot,0.13,0.99,0.29,1.1"
          "smoothOut,0.36,0,0.66,-0.56"
        ];
        animation = [
          "windows,1,4,wind,slide"
          "windowsOut,1,4,smoothOut,slide"
          "border,1,10,default"
          "fade,1,6,default"
          "workspaces,1,4,overshot,slidevert"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        vfr = true; # variable refresh when idle — a real battery win on a laptop
        vrr = 1; # adaptive sync where the panel supports it
      };

      # ── Keybinds. SUPER is the Windows key.
      "$mod" = "SUPER";
      "$terminal" = "kitty";

      bind = [
        # Core
        "$mod, Return, exec, $terminal"
        "$mod, Q, killactive,"
        "$mod, E, exec, nautilus"
        "$mod, V, togglefloating,"
        "$mod, F, fullscreen, 0"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"
        "$mod SHIFT, Q, exit,"

        # Caelestia: launcher, clipboard, session menu.
        "$mod, Space, exec, caelestia shell drawers toggle launcher"
        "$mod, Escape, exec, caelestia shell drawers toggle session"
        "$mod, X, exec, cliphist list | caelestia shell drawers toggle launcher"
        "$mod, L, exec, loginctl lock-session"

        # Focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Move windows
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # Screenshots: region to clipboard, then open the annotator.
        ", Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
        "SHIFT, Print, exec, grim - | wl-copy"
        "$mod, Print, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Colour picker (useful for coursework diagrams/slides).
        "$mod SHIFT, C, exec, hyprpicker -a"
      ];

      # Hold to resize/move with the mouse.
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Media/brightness keys — repeat while held.
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
      ];

      bindl = [
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPause, exec, playerctl play-pause"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioPrev, exec, playerctl previous"
      ];

      # ── Window rules
      windowrulev2 = [
        # Never let an idle-inhibiting fullscreen video be interrupted.
        "idleinhibit fullscreen, class:.*"

        # Float the dialogs that should never be tiled.
        "float, class:^(pavucontrol|nm-connection-editor|blueman-manager)$"
        "float, class:^(virt-manager)$, title:^(?!Virtual Machine Manager).*$"
        "float, title:^(Open File|Save File|Save As|Choose Files)$"

        # Steam/games: skip the compositor's blur and allow tearing.
        "immediate, class:^(steam_app_.*)$"
        "fullscreen, class:^(gamescope)$"

        # Picture-in-picture always on top.
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "size 640 360, title:^(Picture-in-Picture)$"

        # Burp Suite opens tiny splash windows that tile badly.
        "float, class:^(burp-StartBurp)$"
      ];

      # Keep chat and music out of the way on dedicated workspaces.
      workspace = [
        "9, on-created-empty:vesktop"
        "10, on-created-empty:spotify"
      ];
    };
  };

  # Polkit agent, so GUI apps can ask for a password (virt-manager, etc.).
  services.hyprpolkitagent.enable = true;

  # Idle + lock. Caelestia ships its own lock screen; hypridle drives when it
  # fires and when the screen powers off.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        # Dim before locking so you get a chance to move the mouse.
        {
          timeout = 240;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 420;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        # Suspend after 30 min idle, but ONLY on battery — on AC, let long
        # builds, nmap scans and hashcat runs finish unattended.
        # hypridle has no notion of power state, so this has to be a script.
        {
          timeout = 1800;
          on-timeout = toString (pkgs.writeShellScript "idle-suspend-on-battery" ''
            # Any mains supply that is online means we are plugged in.
            for ps in /sys/class/power_supply/*; do
              [ "$(cat "$ps/type" 2>/dev/null)" = "Mains" ] || continue
              [ "$(cat "$ps/online" 2>/dev/null)" = "1" ] && exit 0
            done
            exec systemctl suspend
          '');
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;
      background = [{
        blur_passes = 3;
        blur_size = 8;
        color = "rgba(1e1e2eff)";
      }];
      input-field = [{
        size = "300, 50";
        outline_thickness = 2;
        outer_color = "rgba(cba6f7ee)";
        inner_color = "rgba(1e1e2eff)";
        font_color = "rgba(cdd6f4ff)";
        placeholder_text = "Password...";
        fade_on_empty = false;
        position = "0, -80";
        halign = "center";
        valign = "center";
      }];
    };
  };
}
