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
            layout = "horizontal",
            -- vertical = "right:80%", -- Adjust the percentage for preview width as needed (e.g., 50% for equal split)
            wrap = true,
          },
        },
      })
      -- Override the existing <leader>fp keybinding
      vim.keymap.del("n", "<leader>fp")
      vim.keymap.set("n", "<leader>fp", function()
        require("fzf-lua").files({
          cwd = "/Users/tylerfischer/1-projects",
          cmd = "find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/build/*' -not -path '*/dist/*' -not -path '*/venv/*' -not -path '*/.venv/*' -not -path '*/__pycache__/*' -not -path '*/.idea/*' -not -path '*/.next/*' -not -path '*/.cache/*' -not -path '*/logs/*' -not -path '*/ios/*' -not -path '*/android/*'",
        })
      end, { desc = "Find files in 1-projects" })
    end,
  },
}
