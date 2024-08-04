if vim.g.vscode then
  return
end

local builtin = require("telescope.builtin")

-- Fuzzy search by file name, including hidden (.) files, but excluding the .git directory.
-- Directly using ripgrep (rg) with these additional flags is necessary for this to work.
vim.keymap.set("n", "<leader>pf", function()
  builtin.find_files({ find_command = { "rg", "--files", "--hidden", "-g", "!.git" } })
end)

-- Recent files.
vim.keymap.set("n", "<leader>pr", builtin.oldfiles, {})

-- Fuzzy search for text using ripgrep.
vim.keymap.set("n", "<leader>ps", function()
  builtin.grep_string({
    search = vim.fn.input("Grep > "),
    vimgrep_arguments = {
      "rg",
      "--hidden",
      "--glob",
      "!.git/**",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
    },
  })
end)

-- Fuzzy search through the results of `git ls-files`.
vim.keymap.set("n", "<leader>pg", builtin.git_files, {})
