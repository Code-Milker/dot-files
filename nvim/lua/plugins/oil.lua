return {
  {
    "stevearc/oil.nvim",
    opts = {
      -- Customize the float appearance here
      float = {
        padding = 2, -- Space around the content
        max_width = 0.8, -- 80% of window width (adjust as needed)
        max_height = 0.8, -- 80% of window height (adjust as needed)
        border = "rounded", -- Or "single", "double", etc.
        win_options = {
          winblend = 0, -- Transparency (0 = opaque, higher = more transparent)
        },
      },
      -- Optional: Other global opts, like showing hidden files
      view_options = {
        show_hidden = true,
      },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      {
        "<leader>e",
        function()
          local util = require("lazyvim.util")
          require("oil").open_float(util.root.get())
        end,
        desc = "Open Oil File Explorer at Project Root",
      },
      {
        "<leader>fo", -- Change to your preferred available key (e.g., <leader>od for "Oil Dirs")
        function()
          local util = require("lazyvim.util")
          local root = util.root.get()
          require("fzf-lua").fzf_exec(
            "fd --type d --max-depth 3 --min-depth 2 --absolute-path . "
              .. vim.fn.shellescape(root),
            {
              actions = {
                ["default"] = function(selected)
                  if selected and selected[1] then
                    require("oil").open_float(selected[1])
                  end
                end,
              },
              prompt = "Project Child Dirs> ",
              -- Omit winopts to fully inherit global preconfigured settings (e.g., your larger height/width, borders, etc.)
              -- Only override preview to hidden since this is a dir list (no file previews needed)
              winopts = {
                preview = {
                  hidden = "hidden",
                },
              },
            }
          )
        end,
        desc = "Fzf child dirs of project root and open in Oil",
      },
      {
        "<leader>E",
        function()
          local util = require("lazyvim.util")
          require("oil").open_float()
        end,
        desc = "Open Oil File Explorer at Project Root",
      },
    },
    lazy = false,
    default_file_explorer = true,
  },
}
