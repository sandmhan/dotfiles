#!/bin/bash

echo 'Linking up vimrc'
ln -s ~/dotfiles/vim/vimrc ~/.vim/vimrc
ln -s ~/dotfiles/vim/vimrc ~/.config/nvim/vimrc.vim
ln -s ~/dotfiles/vim/init.lua ~/.config/nvim/lua/init.lua
ln -s ~/dotfiles/vim/init_root.lua ~/.config/nvim/init.lua
