-- Bootstrapping lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

-- Where to add new plugins 
require("lazy").setup({
   "vimwiki/vimwiki",
   event = "BufEnter *.md",
   keys = { "<leader>ww", "<leader>wt" },
   init = function()
       vim.g.vimwiki_folding = ""
       vim.g.vimwiki_list = {
           {
               path = "~/notes/",
               syntax = "markdown",
               ext = ".md",
           },
       }
       vim.g.vimwiki_ext2syntax = {
           [".md"] = "markdown",
           [".markdown"] = "markdown",
           [".mdown"] = "markdown",
       }
   end,
    }
)

-- Loading vimrc config
local vimrc = vim.fn.stdpath("config").. "/vimrc.vim"
vim.cmd.source(vimrc)
