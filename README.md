# nixos-config — Lenovo Legion 5

NixOS + Hyprland + Caelestia for a Lenovo Legion 5 (AMD Ryzen 7 250 /
Radeon 780M iGPU + NVIDIA RTX 5060), set up for ASE CSIE (Informatică
Economică) coursework and security learning (TryHackMe / HackTheBox / CTFs).

- Full-disk encryption (LUKS2) on btrfs, declared with disko, unlocked
  automatically by the TPM so there's no passphrase to type
- Hybrid graphics in **PRIME offload** mode — the dGPU sleeps until asked
- One `rebuild` command applies system *and* dotfiles

> **The repo is expected to live at `~/nixos-config`.** The shell aliases and
> the `nixd` language-server config both hardcode that path. If you put it
> somewhere else, update `home/shell.nix` and `home/nvim/lua/plugins/lsp.lua`.

---

## Table of contents

1. [Layout](#layout)
2. [Before you start](#before-you-start) ← **BIOS settings matter here**
3. [Installation](#installation)
4. [First boot checklist](#first-boot-checklist)
5. [Verifying it all works](#verifying-it-all-works)
6. [Daily use](#daily-use)
7. [Keybindings](#keybindings)
8. [The GPU](#the-gpu)
9. [Security lab](#security-lab)
10. [Uni workflow](#uni-workflow)
11. [Neovim / LazyVim](#neovim--lazyvim)
12. [Maintenance](#maintenance)
13. [Troubleshooting](#troubleshooting)
14. [Where to change things](#where-to-change-things)
15. [Deliberately left out](#deliberately-left-out)
16. [First-build caveat](#first-build-caveat)

---

## Layout

```
flake.nix                      inputs + the `laptop` system
hosts/laptop/
  default.nix                  imports; host-specific settings
  disko.nix                    LUKS2 + btrfs disk layout        ⚠ DESTRUCTIVE
  hardware-configuration.nix   ⚠ PLACEHOLDER — regenerate on the real machine
modules/nixos/
  core.nix                     nix daemon, locale, users, networking, firmware
  boot.nix                     systemd-boot, kernel, zram, plymouth
  desktop.nix                  Hyprland session, greetd, PipeWire, portals, fonts
  nvidia.nix                   RTX 5060 PRIME offload         ⚠ bus IDs to verify
  laptop.nix                   Legion module, power profiles, lid, thermals
  dev.nix                      C/C++, Java 21, .NET, Python, R, DBs, LaTeX, office
  security.nix                 pentest toolkit, VPN plumbing, firewall-on-tun0
  virtualisation.nix           libvirt/QEMU (Kali VMs), Docker
  gaming.nix                   Steam, Proton-GE, gamemode, gamescope
  apps.nix                     Spotify/Spicetify, Discord, media, comms
home/
  default.nix                  home-manager entry: Zen, Caelestia, VSCodium, theming
  hyprland.nix                 compositor config, keybinds, hypridle/hyprlock
  neovim.nix                   Neovim + LazyVim deps (the Nix side)
  nvim/                        the actual LazyVim config (real .lua files)
  shell.nix                    zsh, starship, fzf, zoxide, aliases
  terminal.nix                 kitty
  git.nix                      git, delta, gh, lazygit
```

Adding a module: drop a `.nix` file in `modules/nixos/` and add it to the
`imports` list in `hosts/laptop/default.nix`.

---

## Before you start

### You will need

- A USB stick (≥8 GB) with a **NixOS ISO** (<https://nixos.org/download>),
  written with [Rufus](https://rufus.ie) or `dd`. Which ISO:

  | | Graphical (GNOME) — **recommended** | Minimal |
  | --- | --- | --- |
  | Download | ~3 GB | ~1 GB |
  | Wi-Fi | applet in the top bar, point and click | `wpa_cli`, by hand |
  | Reading this guide | Firefox, on the machine itself | need a second device |
  | Copy-paste commands | yes | retype by hand |
  | Editing config files | GUI editor or terminal | `nano` in the console |

  The graphical ISO is easier for this install specifically, because you have
  to paste PCI bus IDs into a config file partway through. Both reach the same
  result — every command below works on either.

- Ethernet, or your Wi-Fi password
- A second device to read this from **if you use the minimal ISO**
- 40–90 minutes, most of it unattended downloading

> ⚠ **Do not use the graphical installer** (the "Install NixOS" icon on the
> GNOME desktop). Calamares writes its own `/etc/nixos/configuration.nix` and
> knows nothing about flakes, disko or this repo. Open a **terminal** and
> follow the steps below instead.

### Back up Windows first

The disko step **erases the entire drive**, including the Windows recovery
partition. If you ever want to go back, make Lenovo recovery media from
Windows first (Lenovo Vantage → *Recovery*), or at minimum note your Windows
product key — though on a Legion it is burned into the firmware and will
reactivate automatically.

### BIOS settings — do this before installing

Reboot and press **F2** repeatedly at the Lenovo splash (or use the small
**Novo** pinhole button next to the power port, then choose *BIOS Setup*).

| Setting | Set to | Why |
| --- | --- | --- |
| **Graphics / Hybrid Mode** | **Hybrid (Switchable)** — *not* Discrete | ⚠ **Critical.** This config is PRIME *offload*: Hyprland runs on the AMD iGPU. In Discrete/MUX mode the iGPU disappears, `amdgpuBusId` stops resolving and you get a black screen. |
| **Secure Boot** | **Disabled** | You chose plain systemd-boot with no lanzaboote signing. Leaving it on blocks the bootloader. |
| **Boot Mode** | UEFI (not Legacy/CSM) | disko creates a GPT + ESP layout. |
| **Fast Boot** | Disabled | Makes it far easier to get into the boot menu. |
| **Storage / SATA Mode** | AHCI / NVMe (not RAID) | RAID mode hides the SSD from the installer entirely. |

Also disable **Fast Startup** inside Windows before wiping (it leaves the
drive in a half-hibernated state): `powercfg /h off` in an admin prompt.

---

## Installation

### 1. Boot the installer and get online

Press **F12** at the splash for the boot menu, pick the USB stick. On the
graphical ISO, wait for the desktop and open a terminal.

> **If the graphical ISO hangs, freezes on a black screen, or never reaches
> the desktop** — that is almost certainly `nouveau`, the open-source NVIDIA
> driver, choking on the RTX 5060. Blackwell is newer than the nouveau in the
> live image. You do not need a different ISO:
>
> 1. Reboot and, at the ISO's boot menu, press **`e`** to edit the entry.
> 2. Append to the kernel command line:
>    ```
>    modprobe.blacklist=nouveau nouveau.modeset=0
>    ```
> 3. Press **Enter** to boot.
>
> The desktop then runs on the AMD iGPU, which is what this config uses
> anyway. This affects only the installer — your installed system uses the
> proper NVIDIA driver configured in `modules/nixos/nvidia.nix`.
>
> If it still won't boot, use the minimal ISO; every command below is
> identical on both.

Ethernet needs no setup at all — plug in and skip ahead.

**Wi-Fi on the graphical ISO** — use the network applet in the top-right, or:

```sh
nmcli device wifi list
nmcli device wifi connect "YourNetwork" --ask
```

**Wi-Fi on the minimal ISO** — there is no NetworkManager here, so drive
`wpa_supplicant` directly:

```sh
sudo systemctl start wpa_supplicant
wpa_cli
# > add_network
# > set_network 0 ssid "YourNetwork"
# > set_network 0 psk "YourPassword"
# > enable_network 0
# > quit
```

Either way, confirm before continuing:

```sh
ping -c3 nixos.org
```

### 2. Get this repo onto the machine

Git is already on the graphical ISO; `nix-shell -p git` is only needed on the
minimal one, and is harmless on both.

```sh
nix-shell -p git
git clone https://github.com/<you>/nixos-config
cd nixos-config
```

You'll edit files in steps 3–6. Use `nano <file>` (Ctrl+O saves, Ctrl+X
quits) — it's present on both ISOs — or a GUI editor on the graphical one.

### 3. Check the disk name, then partition — ⚠ this erases everything

```sh
lsblk -o NAME,SIZE,MODEL,TRAN
```

If your NVMe drive is **not** `/dev/nvme0n1`, edit the `device` line in
`hosts/laptop/disko.nix` now. If the laptop has two SSDs, be certain which
one you mean.

```sh
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko -- --mode disko ./hosts/laptop/disko.nix
```

You will be prompted twice for the **LUKS passphrase**. Choose something you
can type reliably — see the keyboard-layout warning in
[Troubleshooting](#luks-passphrase-rejected-but-its-definitely-correct).

Everything is now formatted and mounted under `/mnt`. Confirm:

```sh
mount | grep /mnt
```

### 4. Generate the real hardware config

The `--no-filesystems` flag matters: `disko.nix` already declares every
mount, and without the flag you get two conflicting `fileSystems."/"`
definitions and evaluation fails.

```sh
sudo nixos-generate-config --no-filesystems --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix \
        ./hosts/laptop/hardware-configuration.nix
```

This overwrites the placeholder stub. Good.

### 5. Fix the GPU bus IDs — required

```sh
lspci -D | grep -Ei 'vga|3d|display'
```

You will get something like:

```
0000:c1:00.0 VGA compatible controller: AMD ... Radeon 780M
0000:01:00.0 3D controller: NVIDIA Corporation ... GB206M [RTX 5060]
```

Convert each address to NixOS form — **the bus number goes to decimal**, the
other two stay as-is:

| lspci | hex bus | decimal | NixOS value |
| --- | --- | --- | --- |
| `c1:00.0` | `c1` | 193 | `PCI:193:0:0` |
| `01:00.0` | `01` | 1 | `PCI:1:0:0` |

```sh
printf '%d\n' 0xc1     # quick converter
```

Put them in `modules/nixos/nvidia.nix`:

```nix
prime = {
  amdgpuBusId  = "PCI:193:0:0";   # your AMD line
  nvidiaBusId  = "PCI:1:0:0";     # your NVIDIA line
};
```

> Wrong bus IDs are the single most common cause of a black screen on a
> hybrid-graphics install. Double-check them.

### 6. Set your git identity

`home/git.nix` has a placeholder email. Change it now or your first commit
will be attributed wrongly.

### 7. Install

```sh
sudo nixos-install --flake /mnt/$(pwd | cut -d/ -f2-)#laptop
```

Simpler and less error-prone — copy the repo in first, then install:

```sh
sudo mkdir -p /mnt/home/dawid
sudo cp -r . /mnt/home/dawid/nixos-config
sudo nixos-install --flake /mnt/home/dawid/nixos-config#laptop
```

This downloads several GB. Expect 20–60 minutes depending on your connection.
It will ask you to set a **root password** at the end.

```sh
reboot
```

Remove the USB stick as it restarts.

---

## First boot checklist

1. Enter your **LUKS passphrase** at the prompt.
2. You land at the **tuigreet** greeter. You cannot log in as `dawid` yet —
   no password is set. Switch to a TTY with **Ctrl+Alt+F2**, log in as
   `root`, and:

   ```sh
   passwd dawid
   chown -R dawid:users /home/dawid/nixos-config
   ```

3. Ctrl+Alt+F1 back to the greeter, log in as `dawid`.
4. Caelestia takes a few seconds on first launch. Open a terminal with
   **Super+Enter**.
5. First `nvim` launch will clone every plugin and compile treesitter
   parsers — give it a minute and don't interrupt it.
6. Build the `nix-index` database so `nix-locate` works (takes a while, run
   it once and forget):

   ```sh
   nix-index
   ```

7. Connect Wi-Fi: click the bar applet, or `nmcli device wifi connect "SSID" --ask`.
8. **Enrol the TPM** so you stop typing the LUKS passphrase — see below.

### Enrol the TPM (stop typing the passphrase)

Until you do this, you get a passphrase prompt on every cold boot. After it,
the laptop unlocks itself and goes straight to the greeter.

First confirm the TPM is present:

```sh
systemd-analyze has-tpm2          # should print "yes"
sudo tpm2_getcap properties-fixed | head
```

Add a **recovery key** first, and write it down somewhere off the laptop. If
the TPM ever refuses (firmware update, BIOS reset, board replacement) this is
how you get back in:

```sh
sudo systemd-cryptenroll --recovery-key /dev/nvme0n1p2
```

Then seal the key to the TPM:

```sh
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
```

Use the real partition — `lsblk` shows it as the one holding `cryptroot`
(the second partition, since partition 1 is the ESP). Reboot to confirm it
unlocks by itself.

Your original passphrase still works and is **not** removed. Keep it.

> ⚠ **What this does and doesn't protect against.** Because you're running
> without Secure Boot, sealing to PCR 0+7 stops someone who pulls the SSD out
> and reads it in another machine — the realistic laptop-theft case. It does
> *not* stop someone who steals the laptop intact and boots a USB stick: with
> Secure Boot off, the PCRs look the same to the TPM either way and it will
> release the key. Passphrase-only is strictly stronger. If you want both
> convenience and that guarantee, add `lanzaboote`, turn Secure Boot on, and
> re-enrol against PCR 7.
>
> To undo TPM unlocking entirely and go back to typing the passphrase:
>
> ```sh
> sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2
> ```

---

## Verifying it all works

Run these once after install. Every one should succeed.

```sh
# Graphics — iGPU drives the desktop
glxinfo | grep -i 'opengl renderer'          # → AMD Radeon 780M
nvidia-offload glxinfo | grep -i 'opengl renderer'   # → NVIDIA RTX 5060
nvidia-smi                                    # dGPU visible
vainfo                                        # hardware video decode present

# The dGPU is actually asleep when idle (this is the whole point)
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status   # → suspended

# Audio
wpctl status                                  # sinks/sources listed
pactl info | grep 'Server Name'               # → PulseAudio (on PipeWire)

# Legion platform module
ls /sys/module/lenovo_legion_module            # exists
cat /sys/firmware/acpi/platform_profile_choices # low-power balanced performance
powerprofilesctl get

# Virtualisation
systemctl status libvirtd
docker run --rm hello-world
lscpu | grep -i virtual                       # AMD-V present

# Services
systemctl status postgresql
psql -c 'select version();'

# Encryption + TPM
lsblk -o NAME,FSTYPE,MOUNTPOINT          # cryptroot present, btrfs on top
sudo cryptsetup luksDump /dev/nvme0n1p2  # shows enrolled keyslots
systemd-analyze has-tpm2                 # → yes
```

---

## Daily use

The repo is the source of truth. Edit a `.nix` file, then rebuild.

| Command | What it does |
| --- | --- |
| `rebuild` | `nixos-rebuild switch` — apply and make it the default boot entry |
| `rebuild-test` | apply **without** a boot entry; reverts on reboot. Use for risky changes |
| `rebuild-boot` | build and set for next boot, don't apply now |
| `rebuild-dry` | show what *would* change, touch nothing |
| `rollback` | switch back to the previous generation |
| `generations` | list system generations with dates |
| `update` | `nix flake update` — bump every input |
| `gc` | garbage-collect generations older than 14 days |
| `search <pkg>` | search nixpkgs |

Every `rebuild` prints a diff of exactly which packages changed version
(via `nvd`), so you can see what an update actually did.

**If a rebuild breaks the system**, reboot and pick the previous generation
from the systemd-boot menu. Nothing is ever modified in place — the old
generation is still intact on disk.

### Shell shortcuts

| | |
| --- | --- |
| `ll` / `la` / `lt` | eza listings (long / all / tree) |
| `v` | nvim |
| `lg` | lazygit |
| `cat` | bat (syntax-highlighted) |
| `grep` | ripgrep |
| `top` | btop |
| `ports` | `ss -tulpn` — what's listening |
| `cd <partial>` | zoxide; jumps to frecent dirs |
| `mkcd <dir>` | mkdir + cd |
| `gpu <cmd>` | run a command on the dGPU |

---

## Keybindings

### Hyprland (`Super` = Windows key)

| Key | Action |
| --- | --- |
| `Super + Enter` | terminal (kitty) |
| `Super + Space` | Caelestia app launcher |
| `Super + Escape` | Caelestia session menu (logout/reboot/shutdown) |
| `Super + E` | file manager |
| `Super + Q` | close window |
| `Super + Shift + Q` | exit Hyprland |
| `Super + F` | fullscreen |
| `Super + V` | toggle floating |
| `Super + J` | toggle split direction |
| `Super + L` | lock screen |
| `Super + X` | clipboard history |
| `Super + ←↑↓→` | move focus |
| `Super + Shift + ←↑↓→` | move window |
| `Super + 1…0` | switch workspace |
| `Super + Shift + 1…0` | move window to workspace |
| `Super + S` | scratchpad (special workspace) |
| `Super + drag` | move window (LMB) / resize (RMB) |
| `Print` | region screenshot → annotate in swappy |
| `Super + Print` | region screenshot → clipboard |
| `Shift + Print` | full screen → clipboard |
| `Super + Shift + C` | colour picker |

Workspace 9 auto-opens Discord, workspace 10 auto-opens Spotify.

### Neovim (leader = `Space`)

LazyVim defaults apply; these are the additions:

| Key | Action |
| --- | --- |
| `Ctrl + s` | save (any mode) |
| `<leader>y` | yank to system clipboard |
| `<leader>p` | paste over selection without clobbering the register |
| `<leader>d` | delete without yanking |
| `<leader>sr` | replace word under cursor across the file |
| `<leader>cx` | `chmod +x` the current file |
| `<leader>us` | toggle spell check |
| `<leader>uu` | undo tree |
| `<leader>D` | database UI |
| `J` / `K` (visual) | move selected lines up/down |
| `Ctrl + h/j/k/l` | move between splits *and* tmux panes |

---

## The GPU

The AMD iGPU drives the panel and runs Hyprland. The RTX 5060 stays powered
**off** until something explicitly asks for it. This roughly doubles idle
battery life and avoids NVIDIA's Wayland bugs in the compositor.

```sh
nvidia-offload <command>     # run one process on the dGPU
gpu <command>                # same thing, shorter
nvidia-smi                   # dGPU status
nvtop                        # live view of BOTH GPUs
```

**Steam games** — set per-game launch options:

```
nvidia-offload %command%
gamemoderun nvidia-offload %command%      # + CPU governor boost
```

Or launch the whole client on the dGPU with `steam-nvidia` (worse battery in
the library UI; prefer per-game).

**hashcat** is already aliased to run offloaded, so `hashcat -b` uses the 5060.

**CUDA / ML coursework**: prefix with `nvidia-offload`, or use a
`nix-shell`/flake devShell with `cudaSupport`.

> If you ever switch the BIOS to Discrete/MUX mode, this config breaks.
> You would need to drop `prime.offload` and set `prime.sync.enable = true`.

---

## Security lab

**Scope**: this is for machines you are authorised to attack — THM/HTB boxes,
your own VMs, CTFs. Keep it that way.

### VPN

Import your `.ovpn` once, then toggle it from the bar:

```sh
nmcli connection import type openvpn file ~/vpn/thm.ovpn
nmcli connection up thm
```

Or run it directly: `sudo openvpn --config ~/vpn/thm.ovpn`

### Helpers

| | |
| --- | --- |
| `box nibbles` | creates `~/ctf/nibbles/{nmap,loot,exploits,www}` and cd's in |
| `tunip` | prints your VPN IP (the one every writeup tells you to substitute) |
| `serve` | `python3 -m http.server 8000` in the current dir |
| `listen` | `nc -lvnp 4444` |

### Wordlists

Symlinked to the paths every walkthrough assumes, so you can paste commands
verbatim:

```
/usr/share/seclists
/usr/share/wordlists          # includes rockyou.txt
```

### Firewall

Reverse-shell and payload-hosting ports (80, 443, 4444, 4445, 8000, 8080,
9001) are open **only on `tun0`** — never on your home or campus network.
Adjust in `modules/nixos/security.nix`.

### VMs

```sh
virt-manager                  # GUI
quickget kali linux && quickemu --vm kali-linux.conf    # throwaway VM, one command
```

Windows guests work — swtpm and OVMF (Secure Boot capable firmware) are
enabled, so Windows 11's TPM check passes.

### Containers

Docker's bridge is pinned to `172.27.0.0/16` so it cannot collide with the
`10.10.x.x` subnets THM and HTB hand out — a genuinely annoying failure mode
where routes silently break mid-box.

```sh
docker run -d -p 3000:3000 bkimminich/juice-shop
```

---

## Uni workflow

### Databases

PostgreSQL runs as a service and your user is a superuser — `psql` just works.

```sh
psql                                   # your own database
createdb curs_baze_de_date
dbeaver                                # GUI for Postgres/MySQL/Oracle/SQLite
```

MySQL/MariaDB is installed but **disabled** to save resources. Enable it in
`modules/nixos/dev.nix` when a course needs it:

```nix
services.mysql.enable = true;
```

**Oracle** — no sane native package exists on NixOS; use the container:

```sh
docker run -d --name oracle-xe -p 1521:1521 \
  -e ORACLE_PASSWORD=oracle gvenzl/oracle-free:slim
sql system/oracle@localhost:1521/FREEPDB1     # sqlcl is installed
```

A ready-to-uncomment `oci-containers` block in `dev.nix` makes it start
automatically at boot.

### Languages

All toolchains are global and on `PATH`: `gcc`, `clang`, `gdb`, `valgrind`,
`cmake`, `jdk21`, `maven`, `gradle`, `dotnet`, `python3` (with numpy/pandas/
scipy/statsmodels/sklearn/jupyter), `R`.

```sh
dotnet new console -o Lab1 && cd Lab1 && dotnet run
javac Main.java && java Main
jupyter lab
```

For per-project isolation, use `uv` (Python) or a `flake.nix` + `direnv`:

```sh
echo 'use flake' > .envrc && direnv allow
```

### LaTeX

`texliveMedium` covers essentially all coursework. Neovim's `texlab` builds
on save with `tectonic` and forward-searches into Zathura, so `<leader>` jump
takes you from source to the rendered page.

```sh
tectonic -X compile lucrare.tex
```

### Office

LibreOffice with `corefonts` and `liberation_ttf` installed, so `.docx`
files from lecturers keep their layout. Romanian and English spellcheck
dictionaries are present.

---

## Neovim / LazyVim

**Division of labour**: Nix owns the binary and every LSP, formatter, linter,
debugger and compiler. `lazy.nvim` owns the plugins and installs them at
runtime to `~/.local/share/nvim`. `:Lazy` works exactly as upstream expects.

The config is in `home/nvim/` as real `.lua` files (not embedded in Nix
strings), so you get syntax highlighting and LSP while editing it.

**Mason is deliberately disabled** — it downloads generic dynamically-linked
binaries that cannot run on NixOS. If a plugin wants a tool that isn't
installed, add it to `home.packages` in `home/neovim.nix` and rebuild, rather
than re-enabling mason.

### Adding a plugin

Edit `home/nvim/lua/plugins/extras.lua`, then `rebuild`, then `:Lazy sync`.

### Pinning plugin versions

Plugin versions live in `~/.config/nvim/lazy-lock.json`, which is *not* in
this repo by default — so plugins are the one non-reproducible part. To fix
that, once you're happy with your setup:

```sh
cp ~/.config/nvim/lazy-lock.json ~/nixos-config/home/nvim-lazy-lock.json
```

then uncomment the `lazy-lock.json` line in `home/neovim.nix`.

---

## Maintenance

### Updating

```sh
update          # bump all flake inputs
rebuild-dry     # see what would change
rebuild         # apply
```

Commit `flake.lock` afterwards — that file *is* your reproducibility.

To update just one input:

```sh
nix flake update nixpkgs --flake ~/nixos-config
```

### Disk space

Weekly GC and store optimisation are automatic. To force it:

```sh
gc
nix store gc --verbose
du -sh /nix/store
```

If `/boot` fills up, lower `configurationLimit` in `modules/nixos/boot.nix`.

### Firmware

Lenovo ships BIOS/EC updates through LVFS, and these genuinely work:

```sh
fwupdmgr refresh && fwupdmgr get-updates && fwupdmgr update
```

### Sleep and lid behaviour

**Sleep works normally.** What's absent is *hibernation*, which is a different
thing — see [Deliberately left out](#deliberately-left-out).

| | Suspend (configured) | Hibernate (not configured) |
| --- | --- | --- |
| RAM | stays powered | written to disk, machine fully off |
| Resume | ~1–2 s | ~15–30 s |
| Battery drain | ~1–3 %/hr (AMD s2idle) | none |
| Needs swap ≥ RAM | no | yes |

What triggers a suspend:

| Event | Result |
| --- | --- |
| Close the lid, on battery | suspend |
| Close the lid, on AC | suspend |
| Close the lid with an external monitor attached | **stays awake** — you're closing it to use that monitor |
| 30 min idle on battery | suspend |
| 30 min idle on AC | stays awake, so long builds/scans/downloads finish |
| 4 min idle | screen dims |
| 5 min idle | screen locks |
| 7 min idle | display powers off |

Lid behaviour lives in `services.logind` in `modules/nixos/laptop.nix`; the
idle timers are `services.hypridle` in `home/hyprland.nix`.

Closing the lid on AC suspends deliberately. The alternative (`"ignore"`) is
a trap: logind evaluates the lid event only when it fires, so closing the lid
while plugged in and *then* unplugging leaves the machine running in your bag.

To keep it awake for a one-off long job:

```sh
systemd-inhibit --what=handle-lid-switch:idle --why="hashcat" <command>
```

If standby drain looks high, confirm the machine is using s2idle rather than
deep sleep (AMD laptops generally only implement s2idle properly):

```sh
cat /sys/power/mem_sleep          # [s2idle] should be selected
journalctl -b -u systemd-suspend
```

### Battery

```sh
powerprofilesctl list
powerprofilesctl set power-saver
legion_gui                # fan curves, power modes, battery conservation
```

Battery conservation mode (caps charge at ~60%) is worth enabling if the
laptop mostly sits on AC — it meaningfully extends battery lifespan.

---

## Troubleshooting

### Black screen after install

Almost always the PRIME bus IDs. Boot the previous generation (or the
installer USB), and re-check step 5. Also confirm the BIOS is in **Hybrid**
graphics mode, not Discrete.

### `nvidia-smi` says "No devices were found"

The dGPU is runtime-suspended, which is correct and expected. Verify with
`nvidia-offload nvidia-smi` instead. If *that* fails, check
`hardware.nvidia.open = true` is set — Blackwell will not work without it.

### It's asking for the passphrase again after TPM enrolment

The TPM refuses when the measurements it sealed against change — a BIOS/EC
update, a BIOS settings reset, or clearing the TPM will all do it. This is
the designed behaviour, not a fault. Type your passphrase (or recovery key),
then re-enrol:

```sh
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
```

### LUKS passphrase rejected but it's definitely correct

The early-boot prompt uses the **US keyboard layout**, regardless of the
`us,ro` layouts configured for the desktop. If your passphrase contains
characters that move between layouts (`y`/`z`, `@`, `#`, `ă`, `î`), type it
as a US keyboard would produce it. This is why a passphrase of plain ASCII
letters and digits is a good idea.

### No greeter, just a black screen or TTY

```sh
systemctl status greetd
journalctl -u greetd -b
```

Usually Hyprland failing to start. Check `journalctl --user -u hyprland -b`.

### Wi-Fi not working

The config uses `iwd` as the NetworkManager backend. If your card misbehaves:

```sh
nmcli device status
journalctl -u iwd -b
```

Fall back by removing `wifi.backend = "iwd"` from `modules/nixos/core.nix`.

### Build fails with `undefined variable 'foo'`

A package was renamed or dropped in nixpkgs. Find the current name:

```sh
nix search nixpkgs foo
```

Comment the line out if you don't need it. See
[First-build caveat](#first-build-caveat).

### `error: infinite recursion encountered`

Usually a module referencing `config.<something>` it also defines. Bisect by
commenting imports out of `hosts/laptop/default.nix`.

### Something worked yesterday and doesn't now

```sh
generations                    # find the good one
sudo nixos-rebuild switch --rollback
```

Or pick it from the boot menu.

### Hyprland crashes on a specific app

```sh
journalctl --user -u hyprland -b | tail -50
```

Screen sharing needs the portal: confirm `xdg-desktop-portal-hyprland` is
running with `systemctl --user status xdg-desktop-portal-hyprland`.

---

## Where to change things

| I want to… | Edit |
| --- | --- |
| add a system package | `modules/nixos/` — pick the matching topic file |
| add a user package / dotfile | `home/default.nix` or the relevant `home/*.nix` |
| change keybinds | `home/hyprland.nix` |
| change the bar/launcher/notifications | `programs.caelestia.settings` in `home/default.nix` |
| change terminal look | `home/terminal.nix` |
| add a shell alias | `home/shell.nix` |
| add a Neovim plugin | `home/nvim/lua/plugins/extras.lua` |
| configure an LSP | `home/nvim/lua/plugins/lsp.lua` |
| change monitors / refresh rate | `monitor` in `home/hyprland.nix` |
| enable MySQL / Oracle | `modules/nixos/dev.nix` |
| open a firewall port | `modules/nixos/core.nix` (all) or `security.nix` (VPN only) |
| add another machine | new dir under `hosts/`, new entry in `flake.nix` |

---

## Deliberately left out

- **Hibernation** (suspend-to-disk) — **not the same as sleep.** Normal
  sleep/suspend works fine; see [Sleep and lid behaviour](#sleep-and-lid-behaviour).
  Hibernation writes all of RAM to disk and powers the machine fully off, so
  it needs a swap device at least as large as RAM — and this config uses zram
  (compressed RAM) rather than disk swap. To add it: create a swapfile larger
  than RAM inside the btrfs volume, set `boot.resumeDevice` and the
  `resume_offset` kernel parameter.
- **Secure Boot** — you chose plain systemd-boot. To add it later, bring in
  the `lanzaboote` flake input and enrol keys in the BIOS. This is the one
  addition that would meaningfully strengthen the setup: it is what makes
  TPM auto-unlock safe against a thief booting a USB stick. See the warning
  under [Enrol the TPM](#enrol-the-tpm-stop-typing-the-passphrase).
- **Oracle Database** — ready-to-uncomment Docker block in `dev.nix`.
- **MySQL** — installed, `enable = false`.
- **JetBrains IDEs** — you picked Neovim + VSCodium. Add `jetbrains.idea-community`
  or `jetbrains.rider` to `modules/nixos/dev.nix` if a course forces it.

---

## First-build caveat

This config was written before the machine existed, so it has **never been
evaluated against a real nixpkgs checkout**. The module *options* were
verified against upstream sources, but package *names* drift between nixpkgs
revisions.

Most likely to need adjusting:

- `modules/nixos/security.nix` — security tools get renamed and dropped more
  often than anything else. Nothing in that list is load-bearing for booting.
- `nixfmt-rfc-style`, `texliveMedium`, `nvtopPackages.full`,
  `hunspellDicts.ro_RO`

Catch them before committing to a switch:

```sh
nixos-rebuild dry-build --flake ~/nixos-config#laptop
```

Fix by commenting out the offending line, or finding the current name with
`nix search nixpkgs <name>`.
