if vim.g.vscode then
  return
end

local util = require("conform.util")
local vite_plus = require("greg.vite_plus")

-- vp fmt evaluates vite.config.ts and applies the fmt block. oxfmt LSP cannot load
-- vite.config.ts files that contain functions (e.g. lazyPlugins).
require("conform").formatters.vp_fmt = {
  meta = {
    url = "https://viteplus.dev",
    description = "Vite+ formatter via vp fmt (vite.config.ts fmt block)",
  },
  command = util.from_node_modules("vp"),
  args = { "fmt", "--stdin-filepath", "$FILENAME" },
  stdin = true,
  cwd = function(_, ctx)
    return vim.fs.root(ctx.dirname, { "vite.config.ts", "vite.config.mts", "package.json" })
  end,
}

---@param bufnr integer
---@return boolean
local function is_js_ts_buf(bufnr)
  local ft = vim.bo[bufnr].filetype
  return ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact"
end

---@param bufnr integer
---@return boolean
local function use_vp_fmt(bufnr)
  return vite_plus.is_project(bufnr) and is_js_ts_buf(bufnr)
end

---@param bufnr integer
---@return string|nil project_root
local function js_ts_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end
  return vim.fs.root(name, { "package.json", "prettier.config.js", "prettier.config.mjs", ".prettierrc" })
end

---@param root string
---@return boolean
local function has_local_prettier(root)
  return vim.fn.executable(root .. "/node_modules/.bin/prettier") == 1
end

---@param bufnr integer
---@return conform.FiletypeFormatter
local function js_ts_formatters(bufnr)
  if vite_plus.is_project(bufnr) then
    return { "vp_fmt", lsp_format = "never", timeout_ms = 5000 }
  end

  -- Prefer project prettier (MilkTea, etc.). stop_after_first + prettierd breaks when
  -- the brew prettierd shebang points at a removed Homebrew node (fnm setups).
  local root = js_ts_root(bufnr)
  if root and has_local_prettier(root) then
    return { "prettier", lsp_format = "never" }
  end

  return { "prettierd", "prettier", lsp_format = "never" }
end

require("conform").setup({
  -- vp fmt shells out (~100ms+); run async after save so :w does not block the UI.
  format_on_save = function(bufnr)
    if use_vp_fmt(bufnr) then
      return nil
    end
    return { timeout_ms = 500 }
  end,
  format_after_save = function(bufnr)
    if not use_vp_fmt(bufnr) then
      return nil
    end
    return { timeout_ms = 5000, async = true }
  end,
  formatters_by_ft = {
    lua = { "stylua" },
    typescript = js_ts_formatters,
    typescriptreact = js_ts_formatters,
    javascript = js_ts_formatters,
    javascriptreact = js_ts_formatters,
  },
})
