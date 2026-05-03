if vim.g.vscode then
  return
end

require("nvim-treesitter.configs").setup({
  ensure_installed = {
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
  },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = { enable = true },
})
