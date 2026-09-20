# ── VMs and containers ────────────────────────────────────────────────────────
{ config, pkgs, lib, ... }:
{
  # ── libvirt + QEMU/KVM, for the Kali VM and anything you want to detonate
  #    somewhere it can't touch your real system.
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false; # least privilege; VMs run as the qemu user
      swtpm.enable = true; # virtual TPM — needed to install Windows 11 guests
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ]; # UEFI + Secure Boot capable firmware
      };
    };
    onBoot = "ignore"; # don't auto-start VMs; they're heavy
    onShutdown = "shutdown";
  };
  programs.virt-manager.enable = true;

  # Gives VMs a NAT'd network out of the box instead of making you define one.
  virtualisation.spiceUSBRedirection.enable = true; # pass USB devices into guests

  # ── Containers. Docker for vulnerable-app labs (juice-shop, DVWA), CTF
  #    challenge images, and the Oracle XE container referenced in dev.nix.
  virtualisation.docker = {
    enable = true;
    # Reclaim space from dangling images weekly — CTF images pile up fast.
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" "--filter=until=336h" ];
    };
    # Rootless is safer but breaks host networking, which you need for lab work.
    rootless.enable = false;
  };
  virtualisation.oci-containers.backend = "docker";

  # Docker's default bridge can collide with HTB/THM subnets (10.10.x.x).
  # Pinning it to a 172.x range avoids routes silently breaking mid-box.
  virtualisation.docker.daemon.settings = {
    bip = "172.27.0.1/16";
    default-address-pools = [
      { base = "172.28.0.0/16"; size = 24; }
    ];
  };

  environment.systemPackages = with pkgs; [
    virt-viewer
    spice-gtk
    win-virtio # virtio drivers ISO for Windows guests
    docker-compose
    lazydocker
    dive # inspect image layers
    quickemu # one-command throwaway VMs: `quickget kali linux && quickemu ...`
  ];

  # `dconf` is needed or virt-manager forgets every setting between runs.
  programs.dconf.enable = true;
}
