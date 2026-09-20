# ── Declarative disk layout: GPT → ESP + LUKS2 → btrfs subvolumes ─────────────
#
# !! DESTRUCTIVE !! Applying this ERASES the named disk. Run it exactly once,
# from the installer, before `nixos-install`:
#
#   sudo nix --experimental-features "nix-command flakes" run \
#     github:nix-community/disko -- --mode disko ./hosts/laptop/disko.nix
#
# Check the device name FIRST with `lsblk`. On a Legion 5 the NVMe drive is
# almost always /dev/nvme0n1, but if you have two SSDs you must be sure which.
{ ... }:
{
  disko.devices.disk.main = {
    # TODO(install): verify with `lsblk -o NAME,SIZE,MODEL` before running.
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        # EFI system partition. 1G is generous but lets you keep several
        # generations' kernels+initrds around without ever running out.
        ESP = {
          priority = 1;
          name = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings = {
              # Lets the initrd pass the key to systemd-cryptsetup and enables
              # TRIM pass-through to the SSD (small confidentiality tradeoff:
              # it leaks which blocks are unused — fine for a laptop).
              allowDiscards = true;
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
                # Kept as its own subvolume so snapshots of / never drag in
                # multi-gigabyte VM images, container layers or build caches.
                "@var" = {
                  mountpoint = "/var";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
