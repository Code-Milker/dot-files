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
