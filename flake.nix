{
  description = "dawid — Lenovo Legion 5 (Ryzen 7 250 + RTX 5060) — NixOS + Hyprland + Caelestia";

  # ── inputs = pinned dependencies (see flake.lock) ──────────────────────────
  inputs = {
    # The package set. `nixos-unstable` = rolling, closest to Arch's freshness.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Declarative per-user config (dotfiles, Zen, Caelestia live here).
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # reuse my nixpkgs, don't fetch a 2nd copy
    };


    # Community hardware quirk modules (AMD CPU tuning, laptop/SSD defaults).
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Hyprland — use the project's own flake (recommended over the nixpkgs build).
    # Deliberately NOT following nixpkgs: Hyprland upstream says that breaks
    # their binary cache, so you'd compile the whole compositor yourself.
    hyprland.url = "github:hyprwm/Hyprland";

    # Caelestia shell (the bar/launcher/notifications that runs on top of Hyprland).
    caelestia = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Caelestia dotfiles: the official Hyprland Lua config for the shell.
    caelestia-dots = {
      url = "github:caelestia-dots/caelestia";
      flake = false;
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

    # Prebuilt, weekly-updated database for nix-index / command-not-found, so
    # `nix-index` never has to be run locally.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ── outputs = what this flake builds ───────────────────────────────────────
  outputs =
    { self
    , nixpkgs
    , home-manager
    , nixos-hardware
    , spicetify-nix
    , ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # One machine, named `laptop`. Build with:
      #   sudo nixos-rebuild switch --flake .#laptop
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        inherit system;

        # Make `inputs` and `system` available inside every module.
        specialArgs = { inherit inputs system; };

        modules = [
          ./hosts/laptop

          # Hardware quirks. `common/pc/laptop` enables TLP by default, which
          # would fight power-profiles-daemon, so it is disabled in laptop.nix.
          nixos-hardware.nixosModules.common-cpu-amd
          nixos-hardware.nixosModules.common-cpu-amd-pstate
          nixos-hardware.nixosModules.common-gpu-amd # the Radeon 780M iGPU
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.common-pc-laptop-ssd
          # NOTE: no nixos-hardware nvidia module here on purpose — PRIME offload
          # is configured explicitly in modules/nixos/nvidia.nix so there is one
          # single place that owns the dGPU.

          # System-level Spicetify module (provides programs.spicetify).
          spicetify-nix.nixosModules.spicetify

          # Wire home-manager into the system build so one rebuild does everything.
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.extraSpecialArgs = { inherit inputs system; };
            home-manager.users.dawid = import ./home;
          }
        ];
      };

      # `nix fmt` to format every .nix file in the repo.
      formatter.${system} = pkgs.nixfmt;

      # `nix develop` — a shell with the tools for working on this repo itself.
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ nixfmt nix-output-monitor nvd deadnix statix ];
      };
    };
}
