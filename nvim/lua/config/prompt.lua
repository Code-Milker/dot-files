-- Function to copy all open buffers to clipboard
local function copy_all_buffers_to_clipboard()
  local bufs = vim.api.nvim_list_bufs()
  local contents = {}
  local total_bufs = 0
  local cwd = vim.fn.getcwd()

  -- Count valid buffers first
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buftype", { buf = buf }) == "" then
      local filepath = vim.api.nvim_buf_get_name(buf)
      if filepath and filepath ~= "" and vim.fn.filereadable(filepath) == 1 then
        total_bufs = total_bufs + 1
      end
    end
  end

  -- Collect buffer contents
  local index = 1
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buftype", { buf = buf }) == "" then
      local filepath = vim.api.nvim_buf_get_name(buf)
      if filepath and filepath ~= "" and vim.fn.filereadable(filepath) == 1 then
        -- Get relative path from CWD
        local rel_path = vim.fn.fnamemodify(filepath, ":.")
        -- Get filetype
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
        -- Get lines and content
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        -- Format header and content with Markdown for pretty delimiting
        local formatted = string.format(
          "## File: %s (%d/%d)\n**Filetype:** %s\n**Modified:** %s\n\n```%s\n%s\n```",
          rel_path,
          index,
          total_bufs,
          filetype ~= "" and filetype or "none",
          vim.api.nvim_get_option_value("modified", { buf = buf }) and "Yes" or "No",
          filetype ~= "" and filetype or "text",
          content
        )
        table.insert(contents, formatted)
        index = index + 1
      end
    end
  end

  -- Combine all contents and copy to clipboard
  if #contents > 0 then
    local final_content = table.concat(contents, "\n\n---\n\n")
    vim.fn.setreg("+", final_content)
    print("Copied " .. total_bufs .. " buffer(s) to clipboard.")
  else
    print("No valid buffers to copy.")
  end
end

vim.keymap.set(
  "n",
  "<leader>pa",
  copy_all_buffers_to_clipboard,
  { noremap = true, silent = true, desc = "Copy all buffers to clipboard" }
)

local function copy_project_tree_to_clipboard()
  local tree_output = vim.fn.system("tree -L 2 --dirsfirst") -- Adjust depth with -L
  if vim.v.shell_error ~= 0 then
    print("Error generating tree (ensure 'tree' command is installed).")
    return
  end
  local formatted = string.format("## Project Directory Tree (from %s)\n\n```\n%s\n```", vim.fn.getcwd(), tree_output)
  vim.fn.setreg("+", formatted)
  print("Copied project tree to clipboard.")
end

vim.keymap.set(
  "n",
  "<leader>pt",
  copy_project_tree_to_clipboard,
  { noremap = true, silent = true, desc = "Copy project tree to clipboard" }
)
local function copy_current_buffer_to_clipboard()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_loaded(buf) or vim.api.nvim_get_option_value("buftype", { buf = buf }) ~= "" then
    print("Invalid buffer.")
    return
  end
  local filepath = vim.api.nvim_buf_get_name(buf)
  if not filepath or filepath == "" or vim.fn.filereadable(filepath) == 0 then
    print("No valid file.")
    return
  end
  local rel_path = vim.fn.fnamemodify(filepath, ":.")
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  local formatted = string.format(
    "## File: %s\n**Filetype:** %s\n**Modified:** %s\n\n```%s\n%s\n```",
    rel_path,
    filetype ~= "" and filetype or "none",
    vim.api.nvim_get_option_value("modified", { buf = buf }) and "Yes" or "No",
    filetype ~= "" and filetype or "text",
    content
  )
  vim.fn.setreg("+", formatted)
  print("Copied current buffer to clipboard.")
end

vim.keymap.set(
  "n",
  "<leader>pc",
  copy_current_buffer_to_clipboard,
  { noremap = true, silent = true, desc = "Copy current buffer to clipboard" }
)
local function copy_diagnostics_to_clipboard()
  local diagnostics = vim.diagnostic.get(nil) -- Get all diagnostics
  if #diagnostics == 0 then
    print("No diagnostics found.")
    return
  end
  local contents = {}
  for _, diag in ipairs(diagnostics) do
    local buf_name = vim.api.nvim_buf_get_name(diag.bufnr)
    local rel_path = vim.fn.fnamemodify(buf_name, ":.")
    local severity = vim.diagnostic.severity[diag.severity]
    local entry =
      string.format("- %s: %s (Line %d, Col %d) in %s", severity, diag.message, diag.lnum + 1, diag.col + 1, rel_path)
    table.insert(contents, entry)
  end
  local formatted = "## Diagnostics/Errors\n\n" .. table.concat(contents, "\n")
  vim.fn.setreg("+", formatted)
  print("Copied " .. #diagnostics .. " diagnostic(s) to clipboard.")
end

vim.keymap.set(
  "n",
  "<leader>pd",
  copy_diagnostics_to_clipboard,
  { noremap = true, silent = true, desc = "Copy diagnostics to clipboard" }
)
local function generate_prompt_md()
  local cwd = vim.fn.getcwd()
  local md_file = cwd .. "/prompt.md" -- Output file in current directory

  -- Get project tree
  local tree_output = vim.fn.system("tree -L 2 --dirsfirst") -- Adjust depth as needed
  if vim.v.shell_error ~= 0 then
    print("Error generating tree (ensure 'tree' command is installed).")
    return
  end
  local tree_section = string.format("## Project Directory Tree (from %s)\n\n```\n%s\n```", cwd, tree_output)

  -- Get open buffers (reusing logic from copy_all_buffers_to_clipboard)
  local bufs = vim.api.nvim_list_bufs()
  local buffer_contents = {}
  local total_bufs = 0
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buftype", { buf = buf }) == "" then
      local filepath = vim.api.nvim_buf_get_name(buf)
      if filepath and filepath ~= "" and vim.fn.filereadable(filepath) == 1 then
        total_bufs = total_bufs + 1
      end
    end
  end
  local index = 1
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buftype", { buf = buf }) == "" then
      local filepath = vim.api.nvim_buf_get_name(buf)
      if filepath and filepath ~= "" and vim.fn.filereadable(filepath) == 1 then
        local rel_path = vim.fn.fnamemodify(filepath, ":.")
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        local formatted = string.format(
          "## File: %s (%d/%d)\n**Filetype:** %s\n**Modified:** %s\n\n```%s\n%s\n```",
          rel_path,
          index,
          total_bufs,
          filetype ~= "" and filetype or "none",
          vim.api.nvim_get_option_value("modified", { buf = buf }) and "Yes" or "No",
          filetype ~= "" and filetype or "text",
          content
        )
        table.insert(buffer_contents, formatted)
        index = index + 1
      end
    end
  end
  local buffers_section = "## Open Buffers\n\n" .. table.concat(buffer_contents, "\n\n---\n\n")

  -- Generic prompt rules for high-quality coding
  local prompt_rules = [[
## Prompt Rules

You are an expert software engineer specializing in maintaining strict code quality in repositories. Follow these guidelines for all responses:

- **Adhere to Repo Structure**: Respect the existing file tree and organization. Suggest changes only if they improve modularity without unnecessary refactoring.
- **Code Quality Standards**: Use clean, readable code with proper indentation, meaningful variable names, and comments where needed. Follow language-specific best practices (e.g., PEP8 for Python, Google Style for Java).
- **Error Handling and Edge Cases**: Always include robust error handling, input validation, and consider edge cases.
- **Testing**: Suggest or include unit tests for new code. Aim for high test coverage.
- **Performance and Security**: Optimize for efficiency and security; avoid common vulnerabilities like injection or data leaks.
- **Documentation**: Update README or inline docs as necessary.
- **Minimal Changes**: Make the smallest possible changes to achieve the goal; avoid over-engineering.
- **Version Control**: Suggest commit messages and branching strategies if relevant.
- **Consistency**: Match the style of existing code in the repo.

Respond step-by-step: Analyze the request, review provided context (file tree and buffers), plan changes, then provide code diffs or full files.
]]

  -- Assemble full MD content
  local md_content = {
    "# Prompt Request",
    "",
    "[Describe your coding task or question here. Be specific about files to modify, features to add, or bugs to fix.]",
    "",
    prompt_rules,
    "",
    tree_section,
    "",
    buffers_section,
  }
  local final_md = table.concat(md_content, "\n")

  -- Write to file
  local file = io.open(md_file, "w")
  if file then
    file:write(final_md)
    file:close()
    print("Generated prompt.md in " .. cwd)
    -- Optionally open the file for editing
    vim.cmd("edit " .. md_file)
  else
    print("Error writing to prompt.md")
  end
end

vim.keymap.set(
  "n",
  "<leader>pm",
  generate_prompt_md,
  { noremap = true, silent = true, desc = "Generate prompt.md with context" }
)

local function copy_src_files_to_clipboard()
  local cwd = vim.fn.getcwd()
  local src_dir = cwd .. "/src"
  if vim.fn.isdirectory(src_dir) == 0 then
    print("src/ directory not found.")
    return
  end
  -- Get all files recursively in src/
  local files = vim.fn.globpath(src_dir, "**", false, true)
  local contents = {}
  local total_files = 0
  -- Count valid files first
  for _, file in ipairs(files) do
    if vim.fn.isdirectory(file) == 0 and vim.fn.filereadable(file) == 1 then
      total_files = total_files + 1
    end
  end
  -- Collect file contents
  local index = 1
  for _, file in ipairs(files) do
    if vim.fn.isdirectory(file) == 0 and vim.fn.filereadable(file) == 1 then
      -- Get relative path from CWD
      local rel_path = vim.fn.fnamemodify(file, ":.")
      -- Detect filetype
      local filetype = vim.filetype.match({ filename = file }) or "text"
      -- Read content
      local lines = vim.fn.readfile(file)
      local content = table.concat(lines, "\n")
      -- Format header and content with Markdown
      local formatted = string.format(
        "## File: %s (%d/%d)\n**Filetype:** %s\n\n```%s\n%s\n```",
        rel_path,
        index,
        total_files,
        filetype,
        filetype,
        content
      )
      table.insert(contents, formatted)
      index = index + 1
    end
  end
  -- Combine all contents and copy to clipboard
  if #contents > 0 then
    local final_content = table.concat(contents, "\n\n---\n\n")
    vim.fn.setreg("+", final_content)
    print("Copied " .. total_files .. " file(s) from src/ to clipboard.")
  else
    print("No valid files in src/ to copy.")
  end
end
vim.keymap.set(
  "n",
  "<leader>ps",
  copy_src_files_to_clipboard,
  { noremap = true, silent = true, desc = "Copy all files in src/ to clipboard" }
)
-- Function to copy the output from the last executed command in the terminal buffer to clipboard
local function copy_last_terminal_command_output_to_clipboard()
  local term_bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buftype", { buf = buf }) == "terminal" then
      table.insert(term_bufs, buf)
    end
  end
  if #term_bufs == 0 then
    print("No terminal buffers found.")
    return
  end
  -- Sort by buffer number descending to get the most recent
  table.sort(term_bufs, function(a, b)
    return a > b
  end)
  local last_term_buf = term_bufs[1]
  local lines = vim.api.nvim_buf_get_lines(last_term_buf, 0, -1, false)
  if #lines == 0 then
    print("No content in the last terminal buffer.")
    return
  end
  local prompt_pattern = "^tylerfischer@MacBookPro"
  -- Find the positions of prompts from the end
  local prompt_positions = {}
  for i = #lines, 1, -1 do
    if lines[i]:match(prompt_pattern) then
      table.insert(prompt_positions, i)
      if #prompt_positions == 2 then -- We need the last two prompts
        break
      end
    end
  end
  if #prompt_positions < 2 then
    -- If less than 2 prompts, take from the first prompt's next line to end
    if #prompt_positions == 1 then
      local start_line = prompt_positions[1] + 1
      local output_lines = {}
      for j = start_line, #lines do
        table.insert(output_lines, lines[j])
      end
      local content = table.concat(output_lines, "\n")
      if vim.trim(content) == "" then
        print("No output from the last command.")
        return
      end
      local formatted = string.format("## Last Terminal Command Output\n\n```\n%s\n```", vim.trim(content))
      vim.fn.setreg("+", formatted)
      print("Copied last terminal command output to clipboard.")
      return
    else
      print("No prompts found in terminal buffer.")
      return
    end
  end
  -- Last prompt is prompt_positions[1] (current, possibly empty)
  -- Previous prompt is prompt_positions[2]
  local start_line = prompt_positions[2] + 1 -- Start after the previous prompt (skip command line)
  local end_line = prompt_positions[1] - 1 -- End before the current prompt
  local output_lines = {}
  for i = start_line, end_line do
    table.insert(output_lines, lines[i])
  end
  local content = table.concat(output_lines, "\n")
  if vim.trim(content) == "" then
    print("No output from the last command.")
    return
  end
  local formatted = string.format("## Last Terminal Command Output\n\n```\n%s\n```", vim.trim(content))
  vim.fn.setreg("+", formatted)
  print("Copied last terminal command output to clipboard.")
end
vim.keymap.set(
  "n",
  "<leader>po",
  copy_last_terminal_command_output_to_clipboard,
  { noremap = true, silent = true, desc = "Copy last terminal command output to clipboard" }
)
