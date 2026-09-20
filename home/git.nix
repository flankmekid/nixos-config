{ config, pkgs, lib, ... }:
{
  programs.git = {
    enable = true;
    userName = "dawid";
    # TODO: set your real address (the one your GitHub account uses).
    userEmail = "rogamer266@gmail.com";

    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "zdiff3"; # shows the common ancestor — far easier to resolve
      rerere.enable = true; # remember how you resolved a conflict before
      diff.algorithm = "histogram";
      fetch.prune = true;
      # Sign nothing by default; uncomment once you have a key set up.
      # commit.gpgsign = true;
    };

    aliases = {
      s = "status -sb";
      lg = "log --oneline --graph --decorate --all";
      last = "log -1 HEAD --stat";
      unstage = "restore --staged";
      amend = "commit --amend --no-edit";
    };

    ignores = [
      "result"
      "result-*"
      ".direnv/"
      "*.swp"
      ".DS_Store"
    ];
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.lazygit.enable = true;
}
