-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.del("n", "<leader>e")
vim.keymap.del("n", "<leader>fe")
vim.keymap.del("n", "<leader>fE")
vim.keymap.del("n", "k")
vim.keymap.del("n", "j")
vim.api.nvim_set_keymap("n", "j", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "k", "<Nop>", { noremap = true, silent = true })
vim.keymap.del("n", "<leader>ft")
