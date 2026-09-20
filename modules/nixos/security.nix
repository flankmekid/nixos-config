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

  # ┌───────────────────────────────────────────────────────────────────────┐
  # │ NOTE: this is the list most likely to break on first build. Security  │
  # │ tools get renamed, moved under namespaces or dropped from nixpkgs     │
  # │ more often than anything else here. If evaluation fails with          │
  # │ `undefined variable 'foo'`, comment that one line out and check:      │
  # │     nix search nixpkgs foo                                            │
  # │ Nothing in this list is load-bearing for the system booting.          │
  # └───────────────────────────────────────────────────────────────────────┘
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
    enum4linux-ng
    smbmap
    nbtscan
    snmpcheck
    ldapvi
    onesixtyone

    # ── Web
    burpsuite # the community edition; the workhorse for THM/HTB web boxes
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
    gau
    waybackurls
    arjun

    # ── Exploitation
    metasploit
    exploitdb # searchsploit
    sliver # modern C2, for the red-team learning path
    evil-winrm
    impacket # psexec.py, secretsdump.py, GetNPUsers.py … core for AD boxes
    crackmapexec
    responder
    mitm6
    bloodhound # AD attack-path graphing
    bloodhound-py
    kerbrute
    certipy # AD CS abuse

    # ── Password / hash cracking
    hashcat # will use the RTX 5060 — run it with `nvidia-offload hashcat ...`
    hashcat-utils
    john
    hashid
    hcxtools
    thc-hydra
    medusa
    crunch
    cewl
    wordlists # provides /run/current-system/sw/share/wordlists incl. rockyou

    # ── Reversing / binary exploitation / forensics
    ghidra
    radare2
    rizin
    cutter
    binwalk
    ltrace
    strace
    patchelf
    checksec
    ropgadget
    one_gadget
    gef # GDB Enhanced Features
    foremost
    testdisk
    sleuthkit
    volatility3
    exiftool
    steghide
    stegseek
    zsteg
    outguess

    # ── Crypto / encoding
    cyberchef
    openssl
    hash-identifier
    rsactftool

    # ── Wireless (needs a capable adapter; the Legion's internal card may not
    #    support monitor mode — an external Alfa card usually does)
    aircrack-ng
    wifite2
    kismet
    bettercap

    # ── Privilege escalation helpers (you serve these to the target box)
    linux-exploit-suggester
    pspy
    chisel # port forwarding / pivoting
    ligolo-ng

    # ── Misc
    proxychains-ng
    tor
    seclists # the wordlist collection everything references
    gtfobins # offline GTFOBins lookup
  ];

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
