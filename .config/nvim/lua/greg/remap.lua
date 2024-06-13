vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pq", vim.cmd.Ex)

-- Move lines up and down while respecting scope
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- When deleting newline at end of line, keep cursor at beginning
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor in place when navigating page up and down
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")

-- Keep cursor in middle when doing a local search
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste without replacing buffer with the overwritten content
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Allow yanking content to the outer clipboard
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])


vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)

-- Display code actions for the current line
