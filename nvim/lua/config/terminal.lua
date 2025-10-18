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
local function open_terminal()
  local bufs = vim.api.nvim_list_bufs()
  local has_terminal = false
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
      has_terminal = true
      break
    end
  end
  if has_terminal then
    vim.cmd("split | terminal")
  else
    vim.cmd("terminal")
  end
end
vim.keymap.set("n", "<leader>tn", open_terminal, { noremap = true, silent = true })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
-- Function to toggle terminals (hide if visible, show if hidden)
local function toggle_terminals()
  -- First, check if there are visible terminals
  local has_visible_terms = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
      has_visible_terms = true
      break
    end
  end
  if has_visible_terms then
    -- Hide all visible terminals one by one
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
      -- Hide the first one
      local win = term_wins[1]
      vim.api.nvim_set_current_win(win)
      -- vim.wo.winfixbuf = false
      local total_wins = #vim.api.nvim_list_wins()
      if total_wins == 1 then
        vim.cmd("enew")
      else
        vim.cmd("hide")
      end
    end
    -- After hiding, set current window to a remaining one if needed
    local remaining_wins = vim.api.nvim_list_wins()
    if #remaining_wins > 0 then
      vim.api.nvim_set_current_win(remaining_wins[1])
    end
  else
    -- Find all hidden terminal buffers
    local term_bufs = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
        -- Check if the buffer is not visible in any window
        local is_visible = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            is_visible = true
            break
          end
        end
        if not is_visible then
          table.insert(term_bufs, buf)
        end
      end
    end
    if #term_bufs > 0 then
      -- Show each hidden terminal in a new split
      for _, buf in ipairs(term_bufs) do
        vim.cmd("below split")
        vim.api.nvim_win_set_buf(0, buf)
        -- vim.wo.winfixbuf = true -- Re-set winfixbuf since autocmd doesn't trigger for existing buffers
      end
    else
      -- If no terminals exist, open a new one
      vim.cmd("terminal")
    end
  end
end
vim.keymap.set("n", "<leader>tt", toggle_terminals, { noremap = true, silent = true })
local function rotate_terminals()
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
  while true do
    local current_term_wins = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
        table.insert(current_term_wins, win)
      end
    end
    if #current_term_wins == 0 then
      break
    end
    local win = current_term_wins[1]
    vim.api.nvim_set_current_win(win)
    -- vim.wo.winfixbuf = false
    local total_wins = #vim.api.nvim_list_wins()
    if total_wins == 1 then
      vim.cmd("enew")
    else
      vim.cmd("hide")
    end
  end
  -- Set current window to a remaining one
  local remaining_wins = vim.api.nvim_list_wins()
  if #remaining_wins > 0 then
    vim.api.nvim_set_current_win(remaining_wins[1])
  end
  -- Determine new split command
  local new_split_cmd = is_vertical and "below split" or "vsplit"
  -- Reopen in new orientation
  for i, buf in ipairs(term_bufs) do
    vim.cmd(new_split_cmd)
    vim.api.nvim_win_set_buf(0, buf)
    -- vim.wo.winfixbuf = true
  end
end
vim.keymap.set("n", "<leader>tr", rotate_terminals, { noremap = true, silent = true })

local function delete_terminals()
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
