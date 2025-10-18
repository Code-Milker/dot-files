return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.diagnostics = {
        virtual_text = {
          severity = { min = nil },
        }, -- Disable inline virtual text for diagnostics
      }
      opts.inlay_hints = {
        enabled = false, -- Disable inline inlay hints
      }

      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      -- Disable default K for hover
      keys[#keys + 1] = { "K", false }
      -- Add gh for hover
      keys[#keys + 1] = { "gh", vim.lsp.buf.hover, desc = "Hover" }

      return opts
    end,
  },
}
