-- Define lazy.nvim path
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- Bootstrap lazy.nvim if not installed
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })

  -- Handle cloning errors
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- Add lazy.nvim to runtime path
vim.opt.rtp:prepend(lazypath)
vim.g.lazyvim_picker = "fzf"
-- Configure lazy.nvim
require("lazy").setup({
  -- Plugin specifications
  spec = {
    -- LazyVim base configuration
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "plugins" },
  },

  -- Default settings for all plugins
  defaults = {
    lazy = true, -- Load plugins immediately
    version = false, -- Use latest version instead of pinned
  },

  -- Installation settings
  install = {
    colorscheme = { "savq/melange-nvim" }, -- Preferred colorschemes
  },

  -- Automatic update checker
  checker = {
    enabled = true, -- Enable automatic checking
    notify = false, -- Disable update notifications
  },

  -- Performance optimizations
  performance = {
    rtp = {
      disabled_plugins = { -- Disable built-in plugins
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
