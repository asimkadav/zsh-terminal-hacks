#!/bin/bash
pushd .
echo "Installing zsh.."
brew install zsh
chsh -s `which zsh`
curl -L http://install.ohmyz.sh | sh
cd ~/.oh-my-zsh && git clone git://github.com/zsh-users/zsh-syntax-highlighting.git
source ~/.oh-my-zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh  
brew install z
pip install pygments
popd
cp ~/.vimrc ~/.vimrc.backup
cp ./.vimrc ~/.vimrc
cp -r ./.zsh* ~/

# gh commands
gh alias set patchdiff --shell 'id="$(gh pr list -L100 | fzf | cut -f1)"; [ -n "$id" ] && gh pr diff "$id" --patch'
gh alias set co --shell 'id="$(gh pr list -L100 | fzf | cut -f1)"; [ -n "$id" ] && gh pr checkout "$id"'
gh alias set listdiff --shell 'gh pr list  | fzf --preview "gh pr diff --color=always {+1}"'

echo "New gh commands installed for PR review: gh co, gh patchdiff, gh listdiff"
