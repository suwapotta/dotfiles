-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Force terminal to exit to normal mode with Esc
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit Terminal Mode" })

-- Allow window navigation from terminal mode
vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], { desc = "Go to Left Window" })
vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], { desc = "Go to Lower Window" })
vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], { desc = "Go to Upper Window" })
vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], { desc = "Go to Right Window" })
