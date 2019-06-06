# dotfiles

## Install

1. Install [GNU Stow](https://www.gnu.org/software/stow/)
2. Run the following:

```
cd ~
git clone https://github.com/cppcho/dotfiles.git
cd dotfiles
stow vim
stow bash
# stow mac etc..
```

## Other setup

### Git

```
git config --global core.editor vim
git config --global core.autocrlf input
git config --global color.ui true
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.br branch
git config --global alias.ll "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global alias.la "log --graph --full-history --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global alias.ff "merge --ff-only"
git config --global alias.noff "merge --no-ff"
git config --global merge.log true
git config --global push.default simple
git config --global.alias.recent "!git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ | head -n 100"
git config --global.alias.upstream "!git branch --set-upstream-to=origin/$(git current) $(git current)"
git config --global.alias.bs "!BRANCH=`git recent | fzf` && git checkout ${BRANCH}"
```
