local M = {}

---@return string?
local function git_root()
  local result = vim.system({ "git", "rev-parse", "--show-toplevel" }):wait()
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout or "")
end

---@param stdout string?
local function append_nul_paths(stdout, seen, files)
  if not stdout or stdout == "" then
    return
  end
  for path in stdout:gmatch("[^%z]+") do
    if not seen[path] then
      seen[path] = true
      files[#files + 1] = path
    end
  end
end

--- Unstaged modifications and untracked new files (paths relative to repo root).
---@return string[] files
---@return string? root
function M.changed_files()
  local root = git_root()
  if not root then
    return {}, nil
  end

  local seen = {}
  local files = {}

  local diff = vim
    .system({
      "git",
      "-C",
      root,
      "diff",
      "--name-only",
      "-z",
      "--diff-filter=d",
    }, { text = false })
    :wait()
  if diff.code == 0 then
    append_nul_paths(diff.stdout, seen, files)
  end

  local untracked = vim
    .system({
      "git",
      "-C",
      root,
      "ls-files",
      "-z",
      "--others",
      "--exclude-standard",
    }, { text = false })
    :wait()
  if untracked.code == 0 then
    append_nul_paths(untracked.stdout, seen, files)
  end

  table.sort(files)
  return files, root
end

function M.open_changed_tabs()
  local files, root = M.changed_files()
  if not root then
    vim.notify("GitChangedTabs: not a git repository", vim.log.levels.ERROR)
    return
  end
  if #files == 0 then
    vim.notify("GitChangedTabs: no unstaged or new files", vim.log.levels.INFO)
    return
  end

  local home_tab = vim.fn.tabpagenr()
  local opened = 0
  for _, rel in ipairs(files) do
    local path = vim.fs.joinpath(root, rel)
    vim.cmd.tabnew({ args = { vim.fn.fnameescape(path) } })
    opened = opened + 1
  end

  vim.cmd.tabclose(home_tab)
  vim.cmd.tabfirst()
  vim.notify(("GitChangedTabs: opened %d file(s)"):format(opened), vim.log.levels.INFO)
end

return M
