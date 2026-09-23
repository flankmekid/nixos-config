# ── RTX 5060 (Blackwell) + Radeon 780M iGPU, PRIME render offload ─────────────
#
# Model: the AMD iGPU drives the panel and runs Hyprland. The dGPU stays
# powered DOWN until something explicitly asks for it. You opt in per-process:
#
#   nvidia-offload glxinfo | grep vendor     # sanity check
#   nvidia-offload blender
#
# Steam games: set the launch option to  `nvidia-offload %command%`
# (or use the `steam-nvidia` wrapper defined in gaming.nix).
#
# Why offload and not sync: Hyprland on an AMD iGPU is dramatically less buggy
# than on NVIDIA, and idle battery life roughly doubles when the 5060 is off.
{ config, pkgs, lib, ... }:
{
  # The NVIDIA kernel module + Xwayland driver. Wayland compositors don't use
  # the X driver, but Xwayland (for Steam, older apps) still does.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # required for Steam / 32-bit games / wine
    extraPackages = with pkgs; [
      # iGPU video decode — this is what makes YouTube cheap on battery.
      libva-vdpau-driver
      libvdpau-va-gl
      # NVIDIA's VA-API shim, so ffmpeg/mpv can use the dGPU when offloaded.
      nvidia-vaapi-driver
    ];
  };

  hardware.nvidia = {
    # !! REQUIRED for Blackwell (RTX 50-series) !!
    # The proprietary kernel module does not support these GPUs at all; only
    # the open kernel modules do. Setting this false will leave you with no
    # dGPU and, with modesetting on, possibly no display.
    open = true;

    # Blackwell needs >= 575. `beta` tracks the newest published branch.
    # If a beta regresses, switch to `.stable` (or pin: see README).
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Mandatory for Wayland.
    modesetting.enable = true;

    # Lets the dGPU actually power down. `finegrained` is the piece that makes
    # offload worth it — it turns the card off between offloaded processes.
    # It REQUIRES prime.offload.enable, which is set below.
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    nvidiaSettings = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # provides the `nvidia-offload` wrapper script
      };

      # From `lspci -D | grep -Ei 'vga|3d|display'`: the bus number is hex in
      # lspci and must be written in decimal here (c3 → 195).
      amdgpuBusId = "PCI:195:0:0"; # 0000:c3:00.0 Radeon 780M (drives eDP-1)
      nvidiaBusId = "PCI:1:0:0"; # 0000:01:00.0 RTX 5060
    };
  };

  # The panel is wired to the AMD iGPU (amdgpu_bl1), but the NVIDIA driver
  # also registers a backlight (nvidia_0) that controls nothing. brightnessctl
  # and Caelestia pick nvidia_0 first, so brightness keys did nothing.
  boot.kernelParams = [ "nvidia.NVreg_EnableBacklightHandler=0" ];

  # Wayland environment. These are session-wide so Electron apps, Firefox/Zen
  # and mpv all pick them up.
  #
  # Deliberately NOT set here: GBM_BACKEND, __GLX_VENDOR_LIBRARY_NAME and
  # __NV_PRIME_RENDER_OFFLOAD. Setting those globally would point *every*
  # process at the NVIDIA driver, which defeats the whole point of offload
  # (the dGPU would never sleep) and breaks GL on the iGPU. The
  # `nvidia-offload` wrapper sets them per-process, which is what you want.
  environment.sessionVariables = {
    # Force Wayland where the app supports it.
    NIXOS_OZONE_WL = "1";
    # Use the iGPU's VA-API by default (the dGPU is off most of the time).
    LIBVA_DRIVER_NAME = "radeonsi";
    # Firefox/Zen: native Wayland backend.
    MOZ_ENABLE_WAYLAND = "1";
  };

  # CUDA/compute for hashcat, ML coursework, etc. `nvidia-smi` lives here.
  environment.systemPackages = with pkgs; [
    nvtopPackages.full # per-GPU monitor that shows BOTH the AMD and NVIDIA GPUs
    libva-utils # `vainfo` — check hardware video decode actually works
    mesa-demos # `glxinfo`/`eglinfo` for verifying offload
    vulkan-tools # `vulkaninfo`
  ];
}
