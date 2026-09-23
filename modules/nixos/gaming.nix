# ── Gaming ────────────────────────────────────────────────────────────────────
{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.steam = {
    enable = true;
    # Steam's UI scale comes from Xft.dpi, set in home/caelestia-hypr.nix.
    # STEAM_FORCE_DESKTOPUI_SCALING and -forcedesktopscaling are ignored.
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    # Proton-GE: better compatibility than stock Proton for most titles.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    gamescopeSession.enable = true;
  };

  # gamemode: temporarily switches the CPU governor to performance and raises
  # the process priority while a game is running. Add `gamemoderun %command%`
  # to a game's launch options.
  programs.gamemode = {
    enable = true;
    settings = {
      general.renice = 10;
      # Ask power-profiles-daemon for the performance profile while gaming.
      general.desiredgov = "performance";
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  environment.systemPackages = with pkgs; [
    mangohud # in-game FPS/temp overlay
    protontricks
    lutris
    heroic # Epic / GOG launcher
    vulkan-tools
    prismlauncher

    # Convenience wrapper: launch Steam entirely on the dGPU. For per-game
    # control instead, put `nvidia-offload %command%` in the game's launch
    # options and leave Steam itself on the iGPU (better battery in the UI).
    (writeShellScriptBin "steam-nvidia" ''
      exec nvidia-offload ${config.programs.steam.package}/bin/steam "$@"
    '')
  ];

  # Raise the file-descriptor limit; Proton/Wine games hit the default.
  systemd.settings.Manager.DefaultLimitNOFILE = "1048576";
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "1048576";
    }
  ];

  # Many games (and Wine) need more mmap regions than the default allows.
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;
}
