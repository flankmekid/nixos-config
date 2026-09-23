# ── Hyprland user services ────────────────────────────────────────────────────
#
# The compositor config itself (monitors, input, keybinds, window rules) is
# Caelestia's Lua config plus local overrides — see caelestia-hypr.nix.
# Idle, lock and suspend are handled by the Caelestia shell — see
# programs.caelestia.settings.general.idle in default.nix.
{ ... }:
{
  # Polkit agent, so GUI apps can ask for a password (virt-manager, etc.).
  services.hyprpolkitagent.enable = true;
}
