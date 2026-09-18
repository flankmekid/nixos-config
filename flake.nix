{
  description = "dawid legion 5";

  # ── inputs = pinned dependencies (see flake.lock) ──────────────────────────
  inputs = {
    # The package set. `nixos-unstable` = rolling, closest to Arch's freshness.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Declarative per-user config (dotfiles, Zen, Caelestia live here).
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # reuse my nixpkgs, don't fetch a 2nd copy
    };

    # Hyprland — use the project's own flake (recommended over the nixpkgs build).
    hyprland.url = "github:hyprwm/Hyprland";

    # Caelestia shell (the bar/launcher/notifications that runs on top of Hyprland).
    # NOTE: named `caelestia` so the home-manager import below reads cleanly.
    caelestia = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen browser (not in nixpkgs — community flake, auto-updated).
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Spotify + Spicetify, declaratively (installs Spotify itself).
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ── outputs = what this flake builds ───────────────────────────────────────
  outputs = { self, nixpkgs, home-manager, spicetify-nix, ... }@inputs:
    let
      system = "x86_64-linux";
    in {
      # One machine, named `laptop`. Build with:
      #   sudo nixos-rebuild switch --flake .#laptop
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        inherit system;

        # Make `inputs` and `system` available inside configuration.nix.
        specialArgs = { inherit inputs system; };

        modules = [
          ./configuration.nix

          # System-level Spicetify module (provides programs.spicetify).
          # If this errors, try: spicetify-nix.nixosModules.default
          spicetify-nix.nixosModules.spicetify

          # Wire home-manager into the system build so one rebuild does everything.
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs system; };
          }
        ];
      };
    };
}
