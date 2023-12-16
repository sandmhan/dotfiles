#!bin/bash

echo 'Unlinking vimrc'
unlink ~/.vim/vimrc
unlink ~/.config/nvim/vimrc.vim
echo 'Unlinking root init.lua'
unlink ~/.config/nvim/lua/init.lua
echo 'Unlinking plugins init.lua'
unlink ~/.config/nvim/init.lua
