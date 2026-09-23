# ── Quick installs ────────────────────────────────────────────────────────────
# Packages added with `install <name>` and removed with `uninstall <name>`
# (zsh functions in home/shell.nix). The list is packages.txt, one nixpkgs
# attribute per line; dotted names like python3Packages.requests work, and
# lines starting with # are ignored. It can also be edited by hand.
{ pkgs, lib, ... }:
let
  names = lib.filter (l: l != "" && !lib.hasPrefix "#" l) (
    map lib.trim (lib.splitString "\n" (builtins.readFile ./packages.txt))
  );
in
{
  environment.systemPackages = map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs) names;
}
