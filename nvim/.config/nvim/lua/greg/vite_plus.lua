local M = {}

---@param bufnr integer
---@return boolean
function M.is_project(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return false
  end

  local root = vim.fs.root(name, { "vite.config.ts", "vite.config.mts", "package.json" })
  if not root then
    return false
  end

  local pkg_path = root .. "/package.json"
  if vim.fn.filereadable(pkg_path) == 1 then
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg_path), "\n"))
    if ok and type(data) == "table" then
      for _, key in ipairs({ "dependencies", "devDependencies" }) do
        local deps = data[key]
        if type(deps) == "table" and deps["vite-plus"] then
          return true
        end
      end
      local overrides = data.overrides
      if type(overrides) == "table" and type(overrides.vite) == "string" and overrides.vite:find("vite%-plus") then
        return true
      end
    end
  end

  for _, filename in ipairs({ "vite.config.ts", "vite.config.mts" }) do
    local vite_config = root .. "/" .. filename
    if vim.fn.filereadable(vite_config) == 1 then
      for _, line in ipairs(vim.fn.readfile(vite_config)) do
        if line:find("vite%-plus") then
          return true
        end
      end
    end
  end

  return false
end

return M
