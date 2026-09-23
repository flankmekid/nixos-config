#!/usr/bin/env bash
# fix-config.sh
# Changes the repo for a normal install (graphical installer, no disko, no LUKS).
# Run it from the root of a fresh clone of flankmekid/nixos-config.
# It does not rebuild. It prints the rebuild command at the end.
set -euo pipefail

say()  { printf '\n==> %s\n' "$*"; }
fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

[ -f flake.nix ] && [ -d hosts/laptop ] || fail "Run this script from the root of the nixos-config repo."
[ -f /etc/nixos/hardware-configuration.nix ] || fail "/etc/nixos/hardware-configuration.nix does not exist."
command -v git >/dev/null || fail "git is not installed. Run: nix-shell -p git"

# 1. Apply all fixes: package renames, option renames, kernel, driver, no disko, no TPM.
if [ ! -f hosts/laptop/disko.nix ]; then
  say "The fixes are already applied. Skipping this step."
  APPLY="cat >/dev/null"
else
  say "Applying the fixes"
  APPLY="git apply --index"
fi
eval "$APPLY" <<'FIXES_PATCH_END'
diff --git a/flake.nix b/flake.nix
index f75c112..1723413 100644
--- a/flake.nix
+++ b/flake.nix
@@ -12,12 +12,6 @@
       inputs.nixpkgs.follows = "nixpkgs"; # reuse my nixpkgs, don't fetch a 2nd copy
     };
 
-    # Declarative disk partitioning — makes the LUKS+btrfs layout reproducible
-    # instead of a pile of one-off `cryptsetup`/`mkfs` commands at install time.
-    disko = {
-      url = "github:nix-community/disko";
-      inputs.nixpkgs.follows = "nixpkgs";
-    };
 
     # Community hardware quirk modules (AMD CPU tuning, laptop/SSD defaults).
     nixos-hardware.url = "github:NixOS/nixos-hardware";
@@ -51,7 +45,6 @@
     { self
     , nixpkgs
     , home-manager
-    , disko
     , nixos-hardware
     , spicetify-nix
     , ...
@@ -72,9 +65,6 @@
         modules = [
           ./hosts/laptop
 
-          # Declarative partitioning.
-          disko.nixosModules.disko
-
           # Hardware quirks. `common/pc/laptop` enables TLP by default, which
           # would fight power-profiles-daemon, so it is disabled in laptop.nix.
           nixos-hardware.nixosModules.common-cpu-amd
@@ -102,11 +92,11 @@
       };
 
       # `nix fmt` to format every .nix file in the repo.
-      formatter.${system} = pkgs.nixfmt-rfc-style;
+      formatter.${system} = pkgs.nixfmt;
 
       # `nix develop` — a shell with the tools for working on this repo itself.
       devShells.${system}.default = pkgs.mkShell {
-        packages = with pkgs; [ nixfmt-rfc-style nix-output-monitor nvd deadnix statix ];
+        packages = with pkgs; [ nixfmt nix-output-monitor nvd deadnix statix ];
       };
     };
 }
diff --git a/home/default.nix b/home/default.nix
index 94401f3..54dc903 100644
--- a/home/default.nix
+++ b/home/default.nix
@@ -48,9 +48,8 @@
 
   # VSCodium — extensions declared here so the setup is reproducible.
   # LSPs/compilers come from modules/nixos/dev.nix and are found on PATH.
-  programs.vscode = {
+  programs.vscodium = {
     enable = true;
-    package = pkgs.vscodium;
     profiles.default = {
       extensions = with pkgs.vscode-extensions; [
         # Languages
@@ -106,6 +105,7 @@
     };
   };
   home.pointerCursor = {
+    enable = true;
     gtk.enable = true;
     name = "Bibata-Modern-Classic";
     package = pkgs.bibata-cursors;
diff --git a/home/git.nix b/home/git.nix
index 41d3508..1b7150e 100644
--- a/home/git.nix
+++ b/home/git.nix
@@ -2,37 +2,29 @@
 {
   programs.git = {
     enable = true;
-    userName = "dawid";
-    # TODO: set your real address (the one your GitHub account uses).
-    userEmail = "rogamer266@gmail.com";
 
-    delta = {
-      enable = true;
-      options = {
-        navigate = true;
-        side-by-side = true;
-        line-numbers = true;
-      };
-    };
+    settings = {
+      user.name = "dawid";
+      # TODO: set your real address (the one your GitHub account uses).
+      user.email = "rogamer266@gmail.com";
 
-    extraConfig = {
       init.defaultBranch = "main";
       pull.rebase = true;
       push.autoSetupRemote = true;
-      merge.conflictstyle = "zdiff3"; # shows the common ancestor — far easier to resolve
+      merge.conflictstyle = "zdiff3"; # shows the common ancestor
       rerere.enable = true; # remember how you resolved a conflict before
       diff.algorithm = "histogram";
       fetch.prune = true;
-      # Sign nothing by default; uncomment once you have a key set up.
+      # Sign nothing by default. Uncomment when you have a key.
       # commit.gpgsign = true;
-    };
 
-    aliases = {
-      s = "status -sb";
-      lg = "log --oneline --graph --decorate --all";
-      last = "log -1 HEAD --stat";
-      unstage = "restore --staged";
-      amend = "commit --amend --no-edit";
+      alias = {
+        s = "status -sb";
+        lg = "log --oneline --graph --decorate --all";
+        last = "log -1 HEAD --stat";
+        unstage = "restore --staged";
+        amend = "commit --amend --no-edit";
+      };
     };
 
     ignores = [
@@ -44,6 +36,16 @@
     ];
   };
 
+  programs.delta = {
+    enable = true;
+    enableGitIntegration = true;
+    options = {
+      navigate = true;
+      side-by-side = true;
+      line-numbers = true;
+    };
+  };
+
   programs.gh = {
     enable = true;
     settings.git_protocol = "ssh";
diff --git a/home/neovim.nix b/home/neovim.nix
index 17e9792..dd5552f 100644
--- a/home/neovim.nix
+++ b/home/neovim.nix
@@ -47,7 +47,7 @@
 
     # ── Nix
     nixd
-    nixfmt-rfc-style
+    nixfmt
 
     # ── C / C++
     clang-tools # clangd + clang-format
@@ -65,7 +65,7 @@
     # ── Python
     basedpyright
     ruff
-    debugpy
+    python3Packages.debugpy
 
     # ── SQL
     sqlfluff
@@ -80,7 +80,7 @@
     taplo
     marksman
     markdownlint-cli2
-    nodePackages.prettier
+    prettier
 
     # ── Shell
     bash-language-server
diff --git a/hosts/laptop/default.nix b/hosts/laptop/default.nix
index 0b33a68..2ac27b5 100644
--- a/hosts/laptop/default.nix
+++ b/hosts/laptop/default.nix
@@ -3,11 +3,9 @@
 { ... }:
 {
   imports = [
-    # Generated on the NEW laptop. See README — with disko you generate it with
-    #   nixos-generate-config --no-filesystems --root /mnt
-    # so it does NOT fight the disk layout declared in disko.nix.
+    # Copied from /etc/nixos/hardware-configuration.nix after the graphical
+    # install. It declares the disks, so no disko here.
     ./hardware-configuration.nix
-    ./disko.nix
 
     ../../modules/nixos/core.nix
     ../../modules/nixos/boot.nix
diff --git a/hosts/laptop/disko.nix b/hosts/laptop/disko.nix
deleted file mode 100644
index 4671e6c..0000000
--- a/hosts/laptop/disko.nix
+++ /dev/null
@@ -1,86 +0,0 @@
-# ── Declarative disk layout: GPT → ESP + LUKS2 → btrfs subvolumes ─────────────
-#
-# !! DESTRUCTIVE !! Applying this ERASES the named disk. Run it exactly once,
-# from the installer, before `nixos-install`:
-#
-#   sudo nix --experimental-features "nix-command flakes" run \
-#     github:nix-community/disko -- --mode disko ./hosts/laptop/disko.nix
-#
-# Check the device name FIRST with `lsblk`. On a Legion 5 the NVMe drive is
-# almost always /dev/nvme0n1, but if you have two SSDs you must be sure which.
-{ ... }:
-{
-  disko.devices.disk.main = {
-    # TODO(install): verify with `lsblk -o NAME,SIZE,MODEL` before running.
-    device = "/dev/nvme0n1";
-    type = "disk";
-    content = {
-      type = "gpt";
-      partitions = {
-        # EFI system partition. 1G is generous but lets you keep several
-        # generations' kernels+initrds around without ever running out.
-        ESP = {
-          priority = 1;
-          name = "ESP";
-          size = "1G";
-          type = "EF00";
-          content = {
-            type = "filesystem";
-            format = "vfat";
-            mountpoint = "/boot";
-            mountOptions = [ "umask=0077" ];
-          };
-        };
-
-        luks = {
-          size = "100%";
-          content = {
-            type = "luks";
-            name = "cryptroot";
-            settings = {
-              # Lets the initrd pass the key to systemd-cryptsetup and enables
-              # TRIM pass-through to the SSD (small confidentiality tradeoff:
-              # it leaks which blocks are unused — fine for a laptop).
-              allowDiscards = true;
-
-              # Ask the TPM2 chip for the key at boot instead of prompting.
-              # This does nothing until you actually enrol the key — see
-              # "Enrol the TPM" in the README. Until then (and any time the
-              # TPM refuses), you get the normal passphrase prompt, so this
-              # is safe to have set from the very first boot.
-              crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-measure-pcr=yes" ];
-            };
-            content = {
-              type = "btrfs";
-              extraArgs = [ "-f" ];
-              subvolumes = {
-                "@root" = {
-                  mountpoint = "/";
-                  mountOptions = [ "compress=zstd:1" "noatime" ];
-                };
-                "@home" = {
-                  mountpoint = "/home";
-                  mountOptions = [ "compress=zstd:1" "noatime" ];
-                };
-                "@nix" = {
-                  mountpoint = "/nix";
-                  mountOptions = [ "compress=zstd:1" "noatime" ];
-                };
-                # Kept as its own subvolume so snapshots of / never drag in
-                # multi-gigabyte VM images, container layers or build caches.
-                "@var" = {
-                  mountpoint = "/var";
-                  mountOptions = [ "compress=zstd:1" "noatime" ];
-                };
-                "@snapshots" = {
-                  mountpoint = "/.snapshots";
-                  mountOptions = [ "compress=zstd:1" "noatime" ];
-                };
-              };
-            };
-          };
-        };
-      };
-    };
-  };
-}
diff --git a/modules/nixos/boot.nix b/modules/nixos/boot.nix
index 7e1ca51..2af4b7d 100644
--- a/modules/nixos/boot.nix
+++ b/modules/nixos/boot.nix
@@ -11,32 +11,12 @@
   };
   boot.loader.efi.canTouchEfiVariables = true;
 
-  # Newest kernel. Not optional here: the Ryzen 7 250's iGPU and the Legion's
-  # sensors/wifi all want recent amdgpu + platform drivers, and Blackwell
-  # (RTX 5060) needs a kernel new enough for the 575+ NVIDIA modules.
-  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
+  # LTS kernel. The NVIDIA module often fails to build on the newest kernel.
+  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;
 
-  # systemd in the initrd — needed to unlock LUKS with a proper console, and
-  # it gives you a usable emergency shell when something goes wrong at boot.
-  # It is also what makes TPM2 auto-unlock possible at all.
+  # systemd in the initrd: a usable emergency shell if boot fails.
   boot.initrd.systemd.enable = true;
 
-  # ── TPM2, used to unlock the disk without typing a passphrase.
-  #
-  # ⚠ Security note, because this interacts with the decision to run without
-  # Secure Boot: sealing the LUKS key to the TPM protects you against someone
-  # removing the SSD and reading it in another machine (the realistic theft
-  # case). It does NOT protect against someone stealing the laptop intact and
-  # booting a USB stick — with Secure Boot off, PCR 7 looks the same to the
-  # TPM either way, so it would release the key. If you later want both
-  # convenience and that guarantee, add lanzaboote and re-enrol against PCR 7
-  # with Secure Boot on. Your passphrase always remains as a fallback.
-  security.tpm2 = {
-    enable = true;
-    pkcs11.enable = true;
-    tctiEnvironment.enable = true;
-  };
-  environment.systemPackages = [ pkgs.tpm2-tools ];
 
   # Quiet, flicker-free boot into the Hyprland greeter.
   boot.kernelParams = [ "quiet" "splash" "rd.udev.log_level=3" ];
diff --git a/modules/nixos/desktop.nix b/modules/nixos/desktop.nix
index 0e82585..30f3c1d 100644
--- a/modules/nixos/desktop.nix
+++ b/modules/nixos/desktop.nix
@@ -24,7 +24,7 @@
     enable = true;
     settings.default_session = {
       command = lib.concatStringsSep " " [
-        "${pkgs.greetd.tuigreet}/bin/tuigreet"
+        "${pkgs.tuigreet}/bin/tuigreet"
         "--time"
         "--remember"
         "--remember-user-session"
@@ -68,7 +68,7 @@
   # ── Removable media: auto-mount USB sticks without root.
   services.udisks2.enable = true;
   services.gvfs.enable = true;
-  programs.file-roller.enable = true;
+  environment.systemPackages = [ pkgs.file-roller ];
 
   # ── Fonts. Caelestia wants a Nerd Font + Material symbols; the rest is so
   #    that PDFs, .docx coursework and Romanian diacritics all render right.
@@ -80,7 +80,7 @@
       inter # UI font
       noto-fonts
       noto-fonts-cjk-sans
-      noto-fonts-emoji
+      noto-fonts-color-emoji
       liberation_ttf # metric-compatible Arial/Times/Courier — matters for .docx
       corefonts # actual MS fonts, for documents that demand them
     ];
@@ -101,7 +101,7 @@
   # Dark theme by default across GTK/Qt (Caelestia is a dark shell).
   qt = {
     enable = true;
-    platformTheme = "gtk2";
-    style = "gtk2";
+    platformTheme = "gnome";
+    style = "adwaita-dark";
   };
 }
diff --git a/modules/nixos/dev.nix b/modules/nixos/dev.nix
index cf3b6f8..11b6ff6 100644
--- a/modules/nixos/dev.nix
+++ b/modules/nixos/dev.nix
@@ -19,12 +19,12 @@
       libgcc
       xz
       # X/GUI libs — enough for most prebuilt GUI tools and Electron blobs.
-      xorg.libX11
-      xorg.libXext
-      xorg.libXrender
-      xorg.libXtst
-      xorg.libXi
-      xorg.libxcb
+      libx11
+      libxext
+      libxrender
+      libxtst
+      libxi
+      libxcb
       libxkbcommon
       fontconfig
       freetype
@@ -149,7 +149,7 @@
     zathura # PDF viewer with SyncTeX (jump editor <-> PDF)
 
     # ── Office + documents
-    libreoffice-fresh
+    libreoffice
     hunspell
     hunspellDicts.en_US
     hunspellDicts.ro_RO
@@ -157,7 +157,7 @@
 
     # ── Shell / web / misc LSPs and formatters (used by Neovim and VSCodium)
     nixd
-    nixfmt-rfc-style
+    nixfmt
     lua-language-server
     stylua
     bash-language-server
diff --git a/modules/nixos/gaming.nix b/modules/nixos/gaming.nix
index 7c8c1eb..45e3cfb 100644
--- a/modules/nixos/gaming.nix
+++ b/modules/nixos/gaming.nix
@@ -4,7 +4,7 @@
   programs.steam = {
     enable = true;
     remotePlay.openFirewall = true;
-    localNetworkGameTransfer.openFirewall = true;
+    localNetworkGameTransfers.openFirewall = true;
     # Proton-GE: better compatibility than stock Proton for most titles.
     extraCompatPackages = [ pkgs.proton-ge-bin ];
     gamescopeSession.enable = true;
@@ -47,7 +47,7 @@
   ];
 
   # Raise the file-descriptor limit; Proton/Wine games hit the default.
-  systemd.extraConfig = "DefaultLimitNOFILE=1048576";
+  systemd.settings.Manager.DefaultLimitNOFILE = "1048576";
   security.pam.loginLimits = [
     { domain = "*"; type = "soft"; item = "nofile"; value = "1048576"; }
   ];
diff --git a/modules/nixos/laptop.nix b/modules/nixos/laptop.nix
index 0f8c43b..8c861f5 100644
--- a/modules/nixos/laptop.nix
+++ b/modules/nixos/laptop.nix
@@ -31,12 +31,12 @@
   #
   # Docked is the deliberate exception — when an external monitor is attached
   # you are closing the lid *in order to* use that monitor.
-  services.logind = {
-    lidSwitch = "suspend";
-    lidSwitchExternalPower = "suspend";
-    lidSwitchDocked = "ignore";
-    # Don't let a long build get killed when you log out of a TTY.
-    killUserProcesses = false;
+  services.logind.settings.Login = {
+    HandleLidSwitch = "suspend";
+    HandleLidSwitchExternalPower = "suspend";
+    HandleLidSwitchDocked = "ignore";
+    # Do not kill a long build when you log out of a TTY.
+    KillUserProcesses = false;
   };
 
   # Modern AMD laptops use s2idle rather than S3; make it explicit so a BIOS
diff --git a/modules/nixos/nvidia.nix b/modules/nixos/nvidia.nix
index d403b8c..1c9a102 100644
--- a/modules/nixos/nvidia.nix
+++ b/modules/nixos/nvidia.nix
@@ -38,7 +38,7 @@
 
     # Blackwell needs >= 575. `beta` tracks the newest published branch.
     # If a beta regresses, switch to `.stable` (or pin: see README).
-    package = config.boot.kernelPackages.nvidiaPackages.beta;
+    package = config.boot.kernelPackages.nvidiaPackages.stable;
 
     # Mandatory for Wayland.
     modesetting.enable = true;
@@ -68,7 +68,7 @@
       # │ `c1:00.0` → `PCI:193:0:0`  (c1 is HEX 193; the bus number must be   │
       # │ written in DECIMAL, the other two stay as-is).                      │
       # └─────────────────────────────────────────────────────────────────────┘
-      amdgpuBusId = "PCI:193:0:0"; # TODO: verify — often c1:00.0 on AMD Legions
+      amdgpuBusId = "PCI:195:0:0"; # TODO: verify — often c1:00.0 on AMD Legions
       nvidiaBusId = "PCI:1:0:0"; # TODO: verify — usually 01:00.0
     };
   };
@@ -94,7 +94,7 @@
   environment.systemPackages = with pkgs; [
     nvtopPackages.full # per-GPU monitor that shows BOTH the AMD and NVIDIA GPUs
     libva-utils # `vainfo` — check hardware video decode actually works
-    glxinfo # `glxinfo`/`eglinfo` for verifying offload
+    mesa-demos # `glxinfo`/`eglinfo` for verifying offload
     vulkan-tools # `vulkaninfo`
   ];
 }
diff --git a/modules/nixos/security.nix b/modules/nixos/security.nix
index 938780a..a68bc3b 100644
--- a/modules/nixos/security.nix
+++ b/modules/nixos/security.nix
@@ -86,7 +86,7 @@
     metasploit
     exploitdb # searchsploit
     evil-winrm
-    impacket # psexec.py, secretsdump.py, GetNPUsers.py … core for AD boxes
+    python3Packages.impacket # psexec.py, secretsdump.py, GetNPUsers.py … core for AD boxes
     responder
     mitm6
     kerbrute
diff --git a/modules/nixos/virtualisation.nix b/modules/nixos/virtualisation.nix
index 1f5cbf5..e696e3c 100644
--- a/modules/nixos/virtualisation.nix
+++ b/modules/nixos/virtualisation.nix
@@ -9,10 +9,6 @@
       package = pkgs.qemu_kvm;
       runAsRoot = false; # least privilege; VMs run as the qemu user
       swtpm.enable = true; # virtual TPM — needed to install Windows 11 guests
-      ovmf = {
-        enable = true;
-        packages = [ pkgs.OVMFFull.fd ]; # UEFI + Secure Boot capable firmware
-      };
     };
     onBoot = "ignore"; # don't auto-start VMs; they're heavy
     onShutdown = "shutdown";
@@ -49,7 +45,7 @@
   environment.systemPackages = with pkgs; [
     virt-viewer
     spice-gtk
-    win-virtio # virtio drivers ISO for Windows guests
+    virtio-win # virtio drivers ISO for Windows guests
     docker-compose
     lazydocker
     dive # inspect image layers
FIXES_PATCH_END

# 2. Use the hardware config from the installer. It declares the disks.
say "Copying /etc/nixos/hardware-configuration.nix"
cp /etc/nixos/hardware-configuration.nix hosts/laptop/hardware-configuration.nix
grep -q 'fileSystems."/"' hosts/laptop/hardware-configuration.nix \
  || fail "The hardware config has no root filesystem. Do not rebuild."

# 3. Use the stateVersion of this install.
sv=$(sed -n 's/.*system\.stateVersion *= *"\([0-9.]*\)".*/\1/p' /etc/nixos/configuration.nix | head -n1)
if [ -n "$sv" ]; then
  sed -i "s/system.stateVersion = \"[0-9.]*\";/system.stateVersion = \"$sv\";/" hosts/laptop/default.nix
  say "stateVersion set to $sv"
else
  say "WARNING: no stateVersion in /etc/nixos/configuration.nix. The repo value stays."
fi

# 4. Read the GPU bus IDs from sysfs and write them in NixOS form.
say "Reading the GPU bus IDs"
amd=""; nv=""
for d in /sys/bus/pci/devices/*; do
  class=$(cat "$d/class"); vendor=$(cat "$d/vendor")
  case "$class" in 0x0300*|0x0302*|0x0380*) ;; *) continue ;; esac
  addr=${d##*/}                      # 0000:c3:00.0
  bus=$((16#$(echo "$addr" | cut -d: -f2)))
  dev=$((16#$(echo "$addr" | cut -d: -f3 | cut -d. -f1)))
  fn=$(echo "$addr" | cut -d. -f2)
  id="PCI:$bus:$dev:$fn"
  [ "$vendor" = "0x1002" ] && amd=$id
  [ "$vendor" = "0x10de" ] && nv=$id
done
if [ -n "$amd" ] && [ -n "$nv" ]; then
  sed -i "s/amdgpuBusId = \"PCI:[0-9:]*\";/amdgpuBusId = \"$amd\";/; s/nvidiaBusId = \"PCI:[0-9:]*\";/nvidiaBusId = \"$nv\";/" modules/nixos/nvidia.nix
  say "AMD: $amd   NVIDIA: $nv"
else
  say "WARNING: cannot find both GPUs. The config keeps PCI:195:0:0 and PCI:1:0:0. Check that the BIOS is in Hybrid mode."
fi

# 5. Flakes read only files that git tracks.
git add -A

# 6. Warn if the user name does not match the config.
id dawid >/dev/null 2>&1 || say "WARNING: user 'dawid' does not exist. The config makes it on rebuild. Run 'sudo passwd dawid' after the rebuild."

say "Done. Next command:"
echo '  sudo env NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild boot --flake .#laptop --max-jobs 2 --cores 4'
