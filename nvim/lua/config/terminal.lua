-- config/terminal.lua

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function(args)
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.api.nvim_set_option_value("buflisted", false, { buf = args.buf })
    vim.bo[args.buf].buflisted = false
    -- vim.wo.winfixbuf = true
    vim.cmd("startinsert")
  end,
})

-- Helper to close all floating windows (prevents oil/fzf interference)
local function close_floats()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then -- It's a float
      vim.api.nvim_win_close(win, false)
    end
  end
end

local function open_terminal()
  close_floats() -- Clear any oil/fzf floats before opening
  local current_buf = vim.api.nvim_get_current_buf()
  local is_empty = (
    vim.api.nvim_buf_line_count(current_buf) == 1
    and vim.fn.getline(1) == ""
    and vim.fn.empty(vim.fn.bufname(current_buf)) == 1
    and vim.api.nvim_get_option_value("buftype", { buf = current_buf }) == ""
  )
  if is_empty then
    vim.cmd("terminal")
  else
    vim.cmd("below split | terminal")
  end
  -- Conditional resize: only if there are non-terminal windows
  local term_win = vim.api.nvim_get_current_win()
  local has_non_term = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_get_option_value("buftype", { buf = vim.api.nvim_win_get_buf(win) }) ~= "terminal" then
      has_non_term = true
      break
    end
  end
  if has_non_term then
    vim.api.nvim_win_set_height(term_win, 15)
  end
end
vim.keymap.set("n", "<leader>tn", open_terminal, { noremap = true, silent = true })

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

local function hide_all_terminals()
  while true do
    local term_wins = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
        table.insert(term_wins, win)
      end
    end
    if #term_wins == 0 then
      break
    end
    local win = term_wins[1]
    vim.api.nvim_set_current_win(win)
    local total_wins = #vim.api.nvim_list_wins()
    if total_wins > 1 then
      vim.cmd("hide")
    else
      -- Last window, try switch to other non-term buf or enew
      local current_buf = vim.api.nvim_get_current_buf()
      local other_buf = nil
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if
          vim.api.nvim_buf_is_loaded(buf)
          and buf ~= current_buf
          and vim.api.nvim_get_option_value("buftype", { buf = buf }) ~= "terminal"
        then
          other_buf = buf
          break
        end
      end
      if other_buf then
        vim.api.nvim_set_current_buf(other_buf)
      else
        vim.cmd("enew")
      end
      vim.cmd("wincmd _") -- Maximize the remaining window
    end
  end
  local remaining_wins = vim.api.nvim_list_wins()
  if #remaining_wins > 0 then
    vim.api.nvim_set_current_win(remaining_wins[1])
  end
end

-- Function to toggle terminals (hide if visible, show if hidden)
local function toggle_terminals()
  close_floats() -- Always clear oil/fzf floats first

  -- Check if there are visible terminals
  local has_visible_terms = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
      has_visible_terms = true
      break
    end
  end
  if has_visible_terms then
    hide_all_terminals()
  else
    -- Find all hidden terminal buffers
    local hidden_term_bufs = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
        local is_visible = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            is_visible = true
            break
          end
        end
        if not is_visible then
          table.insert(hidden_term_bufs, buf)
        end
      end
    end
    if #hidden_term_bufs > 0 then
      local i = 1
      local current_buf = vim.api.nvim_get_current_buf()
      if
        vim.api.nvim_buf_line_count(current_buf) == 1
        and vim.fn.getline(1) == ""
        and vim.fn.empty(vim.fn.bufname(current_buf)) == 1
        and vim.api.nvim_get_option_value("buftype", { buf = current_buf }) == ""
      then
        -- Replace current empty with first terminal
        vim.api.nvim_set_current_buf(hidden_term_bufs[i])
        i = i + 1
      end
      for j = i, #hidden_term_bufs do
        vim.cmd("below split")
        vim.api.nvim_win_set_buf(0, hidden_term_bufs[j])
      end
      -- Conditional resize: only if there are non-terminal windows
      local has_non_term = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_get_option_value("buftype", { buf = vim.api.nvim_win_get_buf(win) }) ~= "terminal" then
          has_non_term = true
          break
        end
      end
      if has_non_term then
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_get_option_value("buftype", { buf = vim.api.nvim_win_get_buf(win) }) == "terminal" then
            vim.api.nvim_win_set_height(win, 15)
          end
        end
      end
    else
      -- If no terminals exist, open a new one
      local current_buf = vim.api.nvim_get_current_buf()
      local is_empty = (
        vim.api.nvim_buf_line_count(current_buf) == 1
        and vim.fn.getline(1) == ""
        and vim.fn.empty(vim.fn.bufname(current_buf)) == 1
        and vim.api.nvim_get_option_value("buftype", { buf = current_buf }) == ""
      )
      if is_empty then
        vim.cmd("terminal")
      else
        vim.cmd("below split | terminal")
      end
      -- Conditional resize for new terminal
      local term_win = vim.api.nvim_get_current_win()
      local has_non_term = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_get_option_value("buftype", { buf = vim.api.nvim_win_get_buf(win) }) ~= "terminal" then
          has_non_term = true
          break
        end
      end
      if has_non_term then
        vim.api.nvim_win_set_height(term_win, 15)
      end
    end
  end
end
vim.keymap.set("n", "<leader>tt", toggle_terminals, { noremap = true, silent = true })

local function rotate_terminals()
  close_floats() -- Clear interference

  local term_wins = {}
  local term_bufs = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
      table.insert(term_wins, win)
      table.insert(term_bufs, buf)
    end
  end
  if #term_wins <= 1 then
    return -- Nothing to rotate or only one terminal
  end
  -- Collect positions with bufs
  local positions_with_buf = {}
  for i, win in ipairs(term_wins) do
    local pos = vim.api.nvim_win_get_position(win)
    table.insert(positions_with_buf, { row = pos[1], col = pos[2], buf = term_bufs[i] })
  end
  -- Determine min/max
  local min_row, max_row, min_col, max_col = math.huge, -math.huge, math.huge, -math.huge
  for _, p in ipairs(positions_with_buf) do
    min_row = math.min(min_row, p.row)
    max_row = math.max(max_row, p.row)
    min_col = math.min(min_col, p.col)
    max_col = math.max(max_col, p.col)
  end
  local is_horizontal = (max_row > min_row) and (max_col == min_col)
  local is_vertical = (max_col > min_col) and (max_row == min_row)
  if not is_horizontal and not is_vertical then
    return -- Mixed or unknown layout
  end
  -- Sort bufs based on current orientation to preserve order
  if is_horizontal then
    table.sort(positions_with_buf, function(a, b)
      return a.row < b.row
    end)
  elseif is_vertical then
    table.sort(positions_with_buf, function(a, b)
      return a.col < b.col
    end)
  end
  term_bufs = {}
  for _, p in ipairs(positions_with_buf) do
    table.insert(term_bufs, p.buf)
  end
  -- Hide all visible terminals
  hide_all_terminals()
  -- Determine new split command
  local new_split_cmd = is_vertical and "below split" or "vsplit"
  -- Reopen in new orientation
  local current_is_empty = (
    vim.api.nvim_buf_line_count(0) == 1
    and vim.fn.getline(1) == ""
    and vim.fn.empty(vim.fn.bufname("")) == 1
    and vim.api.nvim_get_option_value("buftype", { buf = 0 }) == ""
  )
  local k = 1
  if current_is_empty then
    vim.api.nvim_set_current_buf(term_bufs[k])
    k = k + 1
  end
  for i = k, #term_bufs do
    vim.cmd(new_split_cmd)
    vim.api.nvim_win_set_buf(0, term_bufs[i])
  end
  -- Conditional resize: only if there are non-terminal windows
  local has_non_term = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_get_option_value("buftype", { buf = vim.api.nvim_win_get_buf(win) }) ~= "terminal" then
      has_non_term = true
      break
    end
  end
  if has_non_term then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_get_option_value("buftype", { buf = vim.api.nvim_win_get_buf(win) }) == "terminal" then
        vim.api.nvim_win_set_height(win, 15)
      end
    end
  end
end
vim.keymap.set("n", "<leader>tr", rotate_terminals, { noremap = true, silent = true })

local function delete_terminals()
  close_floats() -- Optional: Clean up before delete
  local term_bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
      table.insert(term_bufs, buf)
    end
  end
  for _, buf in ipairs(term_bufs) do
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  print("All terminal buffers deleted.")
end
vim.keymap.set("n", "<leader>td", delete_terminals, { noremap = true, silent = true, desc = "Delete all terminals" })

-- New autocmd: Wipe hidden non-terminal special buffers (e.g., oil/fzf) on toggle to prevent resumption
vim.api.nvim_create_autocmd("WinClosed", {
  pattern = "*",
  callback = function(ev)
    local buf = ev.buf
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
    if buftype ~= "terminal" and (buftype == "nofile" or buftype == "quickfix") then -- Target oil/fzf-like buffers
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end) -- Deferred delete
    end
  end,
})
