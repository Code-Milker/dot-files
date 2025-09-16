return {
  {
    "ibhagwan/fzf-lua",
    -- Your existing config/options here if any
    config = function()
      require("fzf-lua").setup({
        winopts = {
          width = 1,
          height = 1,
          preview = {
            layout = "vertical",
            vertical = "right:50%", -- Adjust the percentage for preview width as needed (e.g., 50% for equal split)
            wrap = true,
          },
        },
      })
    end,
  },
}
