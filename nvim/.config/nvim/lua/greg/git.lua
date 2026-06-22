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

---@param tabnr integer
---@return boolean
local function is_starter_tab(tabnr)
  local tabpage = vim.api.nvim_list_tabpages()[tabnr]
  if not tabpage then
    return false
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "ministarter" then
      return true
    end
  end

  return false
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
  local first_changed_tab = home_tab + 1
  local opened = 0
  for _, rel in ipairs(files) do
    local path = vim.fs.joinpath(root, rel)
    vim.cmd.tabnew({ args = { vim.fn.fnameescape(path) } })
    opened = opened + 1
  end

  local closed_starter = false
  if is_starter_tab(home_tab) then
    closed_starter = pcall(vim.cmd.tabclose, home_tab)
  end

  vim.cmd.tabn(closed_starter and home_tab or first_changed_tab)
  vim.notify(("GitChangedTabs: opened %d file(s)"):format(opened), vim.log.levels.INFO)
end

return M
