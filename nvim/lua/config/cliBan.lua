local dir = "/Users/tylerfischer/1-projects/cliban"
local fzf = require("fzf-lua")
-- Template as a multiline string (JSON with inline comments for guidance)
local add_template = [[
{
  "category": "Job", // Required: One of "Job", "Project", "Health", "Friend", "Fun", "Life"
  "title": "Your task title here", // Required: Non-empty string
  "section": "TODO", // Optional: "TODO", "DOING", or "DONE" (defaults to "TODO")
  "attributes": { // Optional: Add/remove keys as needed. Each value is an array of strings.
    "goal": ["Main objective"],
    "note": ["Any notes", "Multi-line if needed"],
    "deadline": ["2023-12-31"]
    // Allowed keys: "goal", "done", "remaining", "note", "outcome", "deadline", "target"
    // Example: "target": ["Milestone 1", "Milestone 2"]
  }
}
]]
vim.keymap.set("n", "<leader>kg", function()
  local cmd = string.format("cd %s && bun run cli:getKanBan", dir)
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
  local lines = vim.split(add_template, "\n", { trimempty = true })
  local buf = vim.api.nvim_create_buf(false, true) -- Scratch buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", "json", { buf = buf }) -- For syntax highlighting
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf }) -- No save prompt
  vim.api.nvim_buf_set_var(buf, "kanban_mode", "add") -- Set mode for submit
  vim.api.nvim_set_current_buf(buf)
  print("Edit the JSON template, then use <leader>ks to submit.")
end, { desc = "Open add-task template" })
-- Keymap for update: Search tasks with fzf and open edit buffer
vim.keymap.set("n", "<leader>ku", function()
  local cmd = string.format("cd %s && bun run cli:getTasks", dir)
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    print("Error listing tasks: " .. output)
    return
  end
  -- Strip leading junk if present (e.g., "$ bun ..." line)
  local lines = vim.split(output, "\n")
  if #lines > 0 and lines[1]:match("^%s*%$ bun") then
    table.remove(lines, 1)
  end
  output = table.concat(lines, "\n")
  output = vim.trim(output)
  if #output == 0 then
    print("Empty output from command")
    return
  end
  local success, tasks = pcall(vim.json.decode, output)
  if not success then
    print("JSON decode error: " .. tasks)
    print("Raw output: " .. output)
    return
  end
  if not tasks or #tasks == 0 then
    print("No tasks found!")
    return
  end
  -- Create fzf entries: "id\ttitle (category) [section]"
  local entries = {}
  for _, task in ipairs(tasks) do
    table.insert(entries, string.format("%d\t%s (%s) [%s]", task.id, task.title, task.category, task.section))
  end
  -- Function to find task by id
  local function get_task_by_id(id)
    for _, t in ipairs(tasks) do
      if t.id == id then
        return t
      end
    end
  end
  fzf.fzf_exec(entries, {
    prompt = "Select task to update> ",
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local id = tonumber(selected[1]:match("^(%d+)"))
        local task = get_task_by_id(id)
        if not task then
          print("Task not found!")
          return
        end
        -- Build JSON template with current values and comments
        local template_lines = {
          "{",
          string.format('  "id": %d, // Do not change this ID!', task.id),
          string.format(
            '  "category": "%s", // Required: One of "Job", "Project", "Health", "Friend", "Fun", "Life"',
            task.category
          ),
          string.format('  "title": "%s", // Required: Non-empty string', task.title),
          string.format('  "section": "%s", // Optional: "TODO", "DOING", or "DONE"', task.section),
          '  "attributes": { // Optional: Add/remove keys as needed. Each value is an array of strings.',
        }
        local attr_lines = {}
        for key, values in pairs(task.attributes) do
          local vals_str = vim.json.encode(values):gsub("^%[", ""):gsub("%]$", "")
          table.insert(attr_lines, string.format('    "%s": [%s]', key, vals_str))
        end
        for i, line in ipairs(attr_lines) do
          if i < #attr_lines then
            table.insert(template_lines, line .. ",")
          else
            table.insert(template_lines, line)
          end
        end
        table.insert(
          template_lines,
          '    // Allowed keys: "goal", "done", "remaining", "note", "outcome", "deadline", "target"'
        )
        table.insert(template_lines, '    // Example: "target": ["Milestone 1", "Milestone 2"]')
        table.insert(template_lines, "  }")
        table.insert(template_lines, "}")
        local buf = vim.api.nvim_create_buf(false, true) -- Scratch buffer
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, template_lines)
        vim.api.nvim_set_option_value("filetype", "json", { buf = buf }) -- For syntax highlighting
        vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf }) -- No save prompt
        vim.api.nvim_buf_set_var(buf, "kanban_mode", "update") -- Set mode for submit
        vim.api.nvim_set_current_buf(buf)
        print("Edit the JSON template, then use <leader>ks to submit.")
      end,
    },
    preview = {
      fn = function(items)
        if not items or not items[1] then
          return {}
        end
        local id = tonumber(items[1]:match("^(%d+)"))
        local task = get_task_by_id(id)
        if not task then
          return { "No details available" }
        end
        local contents = {
          string.format("ID: %d", task.id),
          string.format("Category: %s", task.category),
          string.format("Title: %s", task.title),
          string.format("Section: %s", task.section),
          "Attributes:",
        }
        for key, values in pairs(task.attributes) do
          for _, val in ipairs(values) do
            table.insert(contents, string.format("- %s: %s", key, val))
          end
        end
        return contents
      end,
    },
    fzf_opts = {
      ["--preview-window"] = "right:50%",
    },
  })
end, { desc = "Update task: Search and edit" })
-- Keymap to submit the template (add or update based on mode)
vim.keymap.set("n", "<leader>ks", function()
  local buf = vim.api.nvim_get_current_buf()
  local mode = vim.api.nvim_buf_get_var(buf, "kanban_mode")
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  -- Remove comments for valid JSON (simple gsub for // comments)
  content = content:gsub("//.-\n", "\n") -- Strip // comments
  local payload = vim.json.decode(content)
  if not payload then
    print("Invalid JSON in buffer!")
    return
  end
  -- Basic validation
  if type(payload.title) ~= "string" or #payload.title == 0 then
    print("Title is required and must be a non-empty string!")
    return
  end
  if mode == "update" and not payload.id then
    print("ID is required for updates!")
    return
  end
  local json_str = vim.json.encode(payload)
  local cmd
  if mode == "add" then
    cmd = string.format("cd %s && echo '%s' | bun run cli:addTasks", dir, json_str)
  elseif mode == "update" then
    cmd = string.format("cd %s && echo '%s' | bun run cli:updateTasks", dir, json_str)
  else
    print("Unknown mode!")
    return
  end
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    print("Error " .. (mode == "add" and "adding" or "updating") .. " task: " .. output)
    return
  end
  -- Close the template buffer
  vim.api.nvim_buf_delete(buf, { force = true })
  -- Capture and open the updated MD buffer
  local md_lines = vim.split(output, "\n", { trimempty = true })
  local md_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(md_buf, 0, -1, false, md_lines)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = md_buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = md_buf })
  vim.api.nvim_set_current_buf(md_buf)
  print("Task " .. (mode == "add" and "added" or "updated") .. "!")
end, { desc = "Submit task template (add/update)" })
