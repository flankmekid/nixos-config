{ config, pkgs, lib, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user.name = "dawid";
      # TODO: set your real address (the one your GitHub account uses).
      user.email = "rogamer266@gmail.com";

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "zdiff3"; # shows the common ancestor
      rerere.enable = true; # remember how you resolved a conflict before
      diff.algorithm = "histogram";
      fetch.prune = true;
      # Sign nothing by default. Uncomment when you have a key.
      # commit.gpgsign = true;

      alias = {
        s = "status -sb";
        lg = "log --oneline --graph --decorate --all";
        last = "log -1 HEAD --stat";
        unstage = "restore --staged";
        amend = "commit --amend --no-edit";
      };
    };

    ignores = [
      "result"
      "result-*"
      ".direnv/"
      "*.swp"
      ".DS_Store"
    ];
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.lazygit.enable = true;
}
