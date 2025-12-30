local dir = "/Users/tylerfischer/1-projects/cliban"

-- Template as a multiline string (JSON with inline comments for guidance)
local template = [[
{
  "category": "Job",  // Required: One of "Job", "Project", "Health", "Friend", "Fun", "Life"
  "title": "Your task title here",  // Required: Non-empty string
  "section": "TODO",  // Optional: "TODO", "DOING", or "DONE" (defaults to "TODO")
  "attributes": {  // Optional: Add/remove keys as needed. Each value is an array of strings.
    "goal": ["Main objective"],
    "note": ["Any notes", "Multi-line if needed"],
    "deadline": ["2023-12-31"]
    // Allowed keys: "goal", "done", "remaining", "note", "outcome", "deadline", "target"
    // Example: "target": ["Milestone 1", "Milestone 2"]
  }
}
]]

vim.keymap.set("n", "<leader>kg", function()
  local cmd = string.format("cd %s && bun run app:getKanBan", dir)
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    print("Error running command: " .. output)
    return
  end
  local lines = vim.split(output, "\n", { trimempty = true })
  local buf = vim.api.nvim_create_buf(false, true) -- false: not listed in buffer list, true: scratch buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_current_buf(buf)
end, { desc = "Get and open Kanban in buffer" })

-- Keymap to open add-task template
vim.keymap.set("n", "<leader>kt", function()
  local lines = vim.split(template, "\n", { trimempty = true })
  local buf = vim.api.nvim_create_buf(false, true)  -- Scratch buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", "json", { buf = buf })  -- For syntax highlighting
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })  -- No save prompt
  vim.api.nvim_set_current_buf(buf)
  print("Edit the JSON template, then use <leader>ks to submit.")
end, { desc = "Open add-task template" })

-- Keymap to submit the template (parse and run command)
vim.keymap.set("n", "<leader>ks", function()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- Remove comments for valid JSON (simple gsub for // comments)
  content = content:gsub("//.-\n", "\n")  -- Strip // comments

  local payload = vim.json.decode(content)
  if not payload then
    print("Invalid JSON in buffer!")
    return
  end

  -- Optional: Basic Lua validation (Zod handles the rest)
  if type(payload.title) ~= "string" or #payload.title == 0 then
    print("Title is required and must be a non-empty string!")
    return
  end

  local json_str = vim.json.encode(payload)
  local cmd = string.format("cd %s && echo '%s' | bun run app:addTasks", dir, json_str)
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    print("Error adding task: " .. output)
    return
  end

  -- Close the template buffer
  vim.api.nvim_buf_delete(buf, { force = true })

  -- Capture and open the updated MD buffer (from add.cli.ts output)
  local md_lines = vim.split(output, "\n", { trimempty = true })
  local md_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(md_buf, 0, -1, false, md_lines)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = md_buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = md_buf })
  vim.api.nvim_set_current_buf(md_buf)

  print("Task added!")
end, { desc = "Submit add-task template" })
