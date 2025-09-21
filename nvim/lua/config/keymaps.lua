-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.del("n", "<leader>e")
vim.keymap.del("n", "<leader>fe")
vim.keymap.del("n", "<leader>fE")
vim.api.nvim_set_keymap("n", "J", "5jzz", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "K", "5kzz", { noremap = true, silent = true })
vim.keymap.del("n", "<leader>ft")
function _G.console_log_with_random()
  local random_num = math.random(10000, 99999) -- Generate a 5-digit random number
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(
      'yiwoconsole.log("log' .. random_num .. ':", JSON.stringify(<C-r>", null, 2));<Esc>',
      true,
      true,
      true
    ),
    "n",
    true
  )
end
