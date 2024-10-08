vim.g.mapleader = " "

-- Close current tab.
vim.keymap.set("n", "<leader>pq", "<cmd>tabclose<CR>")
vim.keymap.set("n", "<C-w>", "<cmd>tabclose<CR>")

-- Move current tab left or right, using alt left and right.
vim.keymap.set("n", "<leader>{", "<cmd>tabmove -1<CR>")
vim.keymap.set("n", "<leader>}", "<cmd>tabmove +1<CR>")

-- Vertical and horizontal split.
vim.keymap.set("n", "<leader>\\", "<cmd>vsp<CR><C-w>l")
vim.keymap.set("n", "<leader>_", "<cmd>sp<CR><C-w>j")

-- Navigate panes using vim keys.
vim.keymap.set("n", "<leader>h", "<C-w>h")
vim.keymap.set("n", "<leader>j", "<C-w>j")
vim.keymap.set("n", "<leader>k", "<C-w>k")
vim.keymap.set("n", "<leader>l", "<C-w>l")

-- Resize vim panes.
vim.keymap.set("n", "<leader>[", "5<C-w><")
vim.keymap.set("n", "<leader>]", "5<C-w>>")
vim.keymap.set("n", "<leader>-", "5<C-w>-")
vim.keymap.set("n", "<leader>=", "5<C-w>+")

-- Quick navigation.
vim.keymap.set("n", "<leader>qj", "<cmd>cnext<CR>zz", { desc = "Forward qfixlist" })
vim.keymap.set("n", "<leader>qk", "<cmd>cprev<CR>zz", { desc = "Backward qfixlist" })

-- Move lines up and down while respecting scope.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- When deleting newline at end of line, keep cursor at beginning.
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor in place when navigating page up and down.
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")

-- Keep cursor in middle when doing a local search.
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste without replacing buffer with the overwritten content.
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Allow yanking content to the outer clipboard.
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Allow replacing the currently highlighted term.
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Make executable.
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Rename all occurrences from quick fix navigation.
vim.keymap.set("n", "<leader>r", [[:cfdo %s/\<<C-r><C-w>\>/<C-r><C-w>/g<Left><Left><Left>]])

-- Save current file to buffer.
vim.keymap.set("n", "<leader><leader>", function()
  vim.cmd("so")
end)
