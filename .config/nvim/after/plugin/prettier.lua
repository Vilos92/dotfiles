local prettier = require("prettier")

prettier.setup({
  bin = "prettierd", -- alternative to prettier for performance
  filetypes = {
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "less",
    "markdown",
    "scss",
    "typescript",
    "typescriptreact",
    "yaml",
  },
  cli_options = {
    -- My preferred defaults if a config cannot be found.
    print_width = 110,
    tab_width = 2,
    use_tabs = false,
    semi = true,
    single_quote = true,
    trailing_comma = "all",
    bracket_spacing = false,
    bracket_same_line = false,
  },
})

-- Format.
vim.keymap.set("n", "<C-f>", function() vim.cmd("Prettier") end)
