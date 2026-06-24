{
  config = {
    programs.antigravity-cli = {
      permissions = {
        allow = [
          "command(cat *)"
          "command(chmod *)"
          "command(chown *)"
          "command(cp *)"
          "command(curl *)"
          "command(find *)"
          "command(git add *)"
          "command(git branch *)"
          "command(git checkout *)"
          "command(git commit *)"
          "command(git diff *)"
          "command(git log *)"
          "command(git ls-files *)"
          "command(git merge *)"
          "command(git pull *)"
          "command(git push *)"
          "command(git rebase *)"
          "command(git remote *)"
          "command(git reset *)"
          "command(git restore *)"
          "command(git show *)"
          "command(git stash *)"
          "command(git status *)"
          "command(git switch *)"
          "command(grep *)"
          "command(head *)"
          "command(kill *)"
          "command(killall *)"
          "command(ls)"
          "command(ls *)"
          "command(mv *)"
          "command(nix eval *)"
          "command(nix log *)"
          "command(nix path-info *)"
          "command(nix search *)"
          "command(pkill *)"
          "command(rg *)"
          "command(tail *)"
          "command(type *)"
          "command(wget *)"
          "command(whereis *)"
          "command(which *)"
        ];

        ask = [
          "command(build-by-path *)"
          "command(darwin-rebuild *)"
          "command(fix-git *)"
          "command(nh *)"
          "command(nix build *)"
          "command(nix run *)"
          "command(nix shell *)"
          "command(nixos-rebuild *)"
          "command(rsync *)"
          "command(scp *)"
          "command(ssh *)"
          "command(systemctl disable *)"
          "command(systemctl enable *)"
          "command(systemctl reload *)"
          "command(systemctl restart *)"
          "command(systemctl start *)"
          "command(systemctl stop *)"
          "command(why-depends *)"
        ];

        deny = [
          "command(dd *)"
          "command(mkfs *)"
          "command(reboot)"
          "command(reboot *)"
          "command(rm -rf *)"
          "command(shutdown)"
          "command(shutdown *)"
          "command(sudo rm -rf *)"
        ];
      };
    };
  };
}
