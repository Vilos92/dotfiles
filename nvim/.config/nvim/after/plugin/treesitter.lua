if vim.g.vscode then
  return
end

-- nvim-treesitter rewrite (main branch): no nvim-treesitter.configs — see plugin README.
local parsers = {
  "bash",
  "c",
  "gleam",
  "go",
  "html",
  "javascript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "rust",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

require("nvim-treesitter").setup({})

vim.schedule(function()
  require("nvim-treesitter").install(parsers)
end)

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "bash",
    "sh",
    "c",
    "gleam",
    "go",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "lua",
    "markdown",
    "python",
    "query",
    "rust",
    "typescript",
    "typescriptreact",
    "vim",
    "help",
    "yaml",
  },
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()'"
  end,
})
