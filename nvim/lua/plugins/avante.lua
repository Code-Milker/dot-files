return {
  {
    "yetone/avante.nvim",
    build = vim.fn.has("win32") ~= 0
        and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource true"
      or "make",
    event = "VeryLazy",
    lazy = false, -- Optional: Load immediately if you want quick access
    version = false, -- Use the latest version
    opts = {
      selector = {
        provider = "telescope", -- Use Telescope for avante pickers
      },
      provider = "ollama", -- Set Ollama as the default provider
      providers = {
        ollama = {
          endpoint = "http://localhost:11434", -- Default Ollama endpoint
          model = "qwen3-coder:30b-a3b-q8_0", -- Replace with your preferred Ollama model (qwen3-coder:30b-a3b-q8_0)
          temperature = 0, -- Optional: Adjust for response creativity (0 for deterministic)
          max_tokens = 4096, -- Optional: Limit response length
          ["local"] = true, -- Indicates local provider
        },
        -- You can add other providers here if needed, e.g., claude or openai
      },

      behaviour = {
        auto_suggestions = false, -- Experimental; enable if you want auto-code suggestions (may be resource-intensive)
        auto_set_highlight_group = true,
        auto_set_keymaps = true, -- Use default keymaps
        auto_apply_diff_after_generation = false, -- Don't auto-apply changes; review first
        support_paste_from_clipboard = false,
      },
      mappings = {
        ask = "<leader>aa", -- Ask AI about code
        edit = "<leader>ae", -- Edit with AI
        refresh = "<leader>ar", -- Refresh AI response
        -- Diff mappings (in conflict resolution)
        diff = {
          ours = "co", -- Choose ours
          theirs = "ct", -- Choose theirs
          none = "c0", -- Choose none
          both = "cb", -- Choose both
          all_theirs = "ca", -- Choose all theirs
          next = "]x", -- Next conflict
          prev = "[x", -- Prev conflict
        },
        -- Suggestion mappings
        suggestion = {
          accept = "<M-l>", -- Accept suggestion
          next = "<M-]>", -- Next suggestion
          prev = "<M-[>", -- Prev suggestion
          dismiss = "<C-]>", -- Dismiss
        },
        -- Jump mappings
        jump = {
          next = "]]", -- Next hunk
          prev = "[[", -- Prev hunk
        },
        -- Sidebar mappings
        sidebar = {
          switch_windows = "<Tab>",
          reverse_switch_windows = "<S-Tab>",
          toggle_debug_console = "d",
          toggle_hints = "i",
          apply_all = "A",
          apply_target = "a",
        },
      },
      -- Other options like windows, highlights, diff can be customized here if needed
    },
    dependencies = {
      "stevearc/dressing.nvim", -- For input UI
      "nvim-lua/plenary.nvim", -- Core utils
      "MunifTanjim/nui.nvim", -- UI components
      "nvim-tree/nvim-web-devicons", -- Icons (alternative: "echasnovski/mini.icons")
      -- Optional for file selectors (pick one or more)
      "echasnovski/mini.pick",
      "nvim-telescope/telescope.nvim",
      -- Optional for autocompletion in commands/mentions
      "hrsh7th/nvim-cmp",
      -- Optional for other providers
      "zbirenbaum/copilot.lua", -- If using Copilot
      -- For image handling
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
            use_absolute_path = true,
          },
        },
      },
      -- For markdown rendering
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = { file_types = { "markdown", "Avante" } },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
