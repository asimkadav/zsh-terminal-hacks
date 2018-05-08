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

