return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = {
          severity = { min = vim.diagnostic.severity.ERROR },
        }, -- Disable inline virtual text for diagnostics
      },
      inlay_hints = {
        enabled = false, -- Disable inline inlay hints
      },
    },
  },
}
