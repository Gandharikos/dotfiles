{
  config = {
    programs.antigravity-cli = {
      permissions = {
        allow = [
          "command(cat *)"
          "command(find *)"
          "command(git branch *)"
          "command(git diff *)"
          "command(git log *)"
          "command(git ls-files *)"
          "command(git remote *)"
          "command(git show *)"
          "command(git status *)"
          "command(grep *)"
          "command(head *)"
          "command(ls)"
          "command(ls *)"
          "command(nix eval *)"
          "command(nix log *)"
          "command(nix path-info *)"
          "command(nix search *)"
          "command(rg *)"
          "command(tail *)"
          "command(type *)"
          "command(whereis *)"
          "command(which *)"
        ];

        ask = [
          "command(build-by-path *)"
          "command(chmod *)"
          "command(chown *)"
          "command(cp *)"
          "command(curl *)"
          "command(darwin-rebuild *)"
          "command(fix-git *)"
          "command(git add *)"
          "command(git checkout *)"
          "command(git commit *)"
          "command(git merge *)"
          "command(git pull *)"
          "command(git push *)"
          "command(git rebase *)"
          "command(git reset *)"
          "command(git restore *)"
          "command(git stash *)"
          "command(git switch *)"
          "command(kill *)"
          "command(killall *)"
          "command(mv *)"
          "command(nh *)"
          "command(nix build *)"
          "command(nix run *)"
          "command(nix shell *)"
          "command(nixos-rebuild *)"
          "command(pkill *)"
          "command(rsync *)"
          "command(scp *)"
          "command(ssh *)"
          "command(systemctl disable *)"
          "command(systemctl enable *)"
          "command(systemctl reload *)"
          "command(systemctl restart *)"
          "command(systemctl start *)"
          "command(systemctl stop *)"
          "command(wget *)"
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
