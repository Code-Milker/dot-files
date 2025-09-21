-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = {
    "*.js",
    "*.jsx",
    "*.ts",
    "*.tsx",
    "*.json",
    "*.html",
    "*.htm",
    "*.css",
  },
  command = "silent !prettier --write %",
})
-- Trigger <leader><leader> after LazyVim setup completes
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimStarted",
  callback = function()
    local keys = vim.api.nvim_replace_termcodes("<leader><leader>", true, false, true)
    vim.api.nvim_feedkeys(keys, "n", true)
  end,
})
