# ── Security / CTF tooling: TryHackMe, HackTheBox, coursework labs ────────────
#
# Scope note: this is an offensive-security *learning* environment aimed at
# machines you are authorised to attack (THM/HTB boxes, your own VMs, CTFs).
# Keep it that way.
{ config, pkgs, lib, ... }:
{
  # ── VPN. THM and HTB both hand you an .ovpn file. Connect with:
  #     sudo openvpn --config ~/vpn/thm.ovpn
  #   or import it into NetworkManager once and toggle it from the Caelestia
  #   applet:  nmcli connection import type openvpn file ~/vpn/thm.ovpn
  services.openvpn.servers = { };
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
    networkmanager-openconnect
  ];
  networking.wireguard.enable = true;

  # The tun interface the VPN creates must be allowed to carry your reverse
  # shells back. This trusts the VPN interfaces ONLY — not your home wifi.
  networking.firewall.trustedInterfaces = [ "tun0" "tun1" ];

  # Common reverse-shell / payload-hosting ports, open ONLY on the VPN.
  # This is what lets `nc -lvnp 4444` and `python -m http.server 8000` actually
  # receive a connection back from a target box.
  networking.firewall.interfaces."tun0" = {
    allowedTCPPorts = [ 80 443 4444 4445 8000 8080 9001 ];
    allowedUDPPorts = [ 53 4444 ];
  };

  # ── Wireshark with the `wireshark` group so you can capture without root.
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # the Qt GUI; use pkgs.wireshark-cli for tshark only
  };

  # ── Let nmap do SYN scans etc. without a full root shell.
  security.wrappers.nmap = {
    owner = "root";
    group = "wireshark";
    permissions = "u+rx,g+x";
    capabilities = "cap_net_raw,cap_net_admin,cap_net_bind_service+eip";
    source = "${pkgs.nmap}/bin/nmap";
  };

  # ── The core toolkit. Every name below is a long-lived, stable nixpkgs
  #    attribute, chosen so the first build succeeds without babysitting.
  #    The churnier tools are in the commented EXTRAS block further down.
  environment.systemPackages = with pkgs; [
    # ── Recon / scanning
    nmap
    masscan
    rustscan
    dnsutils # dig, nslookup
    whois
    traceroute
    netcat-gnu
    socat
    tcpdump
    termshark
    arp-scan
    netdiscover
    smbmap
    nbtscan
    enum4linux-ng
    onesixtyone

    # ── Web
    burpsuite # community edition; the workhorse for THM/HTB web boxes
    zap
    ffuf
    feroxbuster
    gobuster
    dirb
    nikto
    wpscan
    sqlmap
    whatweb
    wfuzz
    httpx
    nuclei
    subfinder
    amass

    # ── Exploitation
    metasploit
    exploitdb # searchsploit
    evil-winrm
    impacket # psexec.py, secretsdump.py, GetNPUsers.py … core for AD boxes
    responder
    mitm6
    kerbrute

    # ── Password / hash cracking
    hashcat # uses the RTX 5060 — already aliased to run offloaded
    hashcat-utils
    john
    hashid
    hcxtools
    thc-hydra
    medusa
    crunch
    cewl
    wordlists # provides rockyou.txt — referenced by the tmpfiles rule below

    # ── Reversing / binary exploitation / forensics
    ghidra
    radare2
    rizin
    binwalk
    ltrace
    strace
    patchelf
    checksec
    foremost
    testdisk
    sleuthkit
    exiftool
    steghide

    # ── Crypto / encoding
    openssl

    # ── Wireless (needs a capable adapter; the Legion's internal card may not
    #    support monitor mode — an external Alfa card usually does)
    aircrack-ng
    kismet
    bettercap

    # ── Pivoting / privilege escalation
    chisel # port forwarding
    ligolo-ng
    proxychains-ng
    tor

    # ── Wordlists
    seclists # referenced by the tmpfiles rule below
  ];

  # ┌───────────────────────────────────────────────────────────────────────┐
  # │ EXTRAS — useful, but these attribute names are the ones that actually │
  # │ churn in nixpkgs (renames, namespace moves, removals). They are left  │
  # │ commented so your FIRST build succeeds. Add them a few at a time:     │
  # │                                                                       │
  # │     nix search nixpkgs <name>      # confirm the current name         │
  # │     nix-shell -p <name>            # try it without committing        │
  # │                                                                       │
  # │ then move the line up into the list above and rebuild.                │
  # └───────────────────────────────────────────────────────────────────────┘
  #
  # environment.systemPackages = with pkgs; [
  #   # Active Directory
  #   netexec        # the maintained successor to crackmapexec (which was renamed)
  #   bloodhound     # AD attack-path graphing
  #   bloodhound-py
  #   certipy        # AD CS abuse; may be packaged as certipy-ad
  #   ldapvi
  #
  #   # C2
  #   sliver
  #
  #   # Recon extras
  #   gau
  #   waybackurls
  #   arjun
  #   snmpcheck
  #
  #   # Reversing / forensics extras
  #   cutter         # Rizin GUI
  #   gef            # GDB Enhanced Features
  #   ropgadget      # attribute may be ROPgadget or python3Packages.ropgadget
  #   one_gadget
  #   volatility3
  #
  #   # Steganography
  #   stegseek
  #   zsteg
  #   outguess
  #
  #   # Crypto / CTF helpers
  #   cyberchef
  #   rsactftool
  #   hash-identifier
  #
  #   # Privesc enumeration — often easier to just curl these onto the target
  #   pspy
  #   linux-exploit-suggester
  #
  #   # Wireless
  #   wifite2
  # ];

  # SecLists and rockyou live in the Nix store; symlink them to the paths every
  # walkthrough assumes, so you can copy-paste commands from writeups.
  systemd.tmpfiles.rules = [
    "d /usr/share 0755 root root -"
    "L+ /usr/share/seclists - - - - ${pkgs.seclists}/share/seclists"
    "L+ /usr/share/wordlists - - - - ${pkgs.wordlists}/share/wordlists"
  ];

  # Metasploit wants a database for `db_nmap`, workspaces and loot tracking.
  # Postgres itself is enabled in dev.nix; this just adds the msf database.
  services.postgresql.ensureDatabases = [ "msf" ];
}
